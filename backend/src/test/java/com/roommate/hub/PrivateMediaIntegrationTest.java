package com.roommate.hub;

import com.jayway.jsonpath.JsonPath;
import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.config.R2Properties;
import com.roommate.hub.dto.AdminReportResponseDTO;
import com.roommate.hub.dto.ChatMessageDTO;
import com.roommate.hub.entity.BlockedUser;
import com.roommate.hub.entity.ChatMessage;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.Report;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.net.URI;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// All objects and credentials are synthetic. Presigning runs locally; no HTTP request reaches R2.
@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:private_media_test;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE",
        "storage.r2.enabled=true",
        "storage.r2.endpoint=https://r2.test.invalid",
        "storage.r2.access-key-id=test-only-access-key",
        "storage.r2.secret-access-key=test-only-secret-key",
        "storage.r2.bucket=public-test",
        "storage.r2.private-bucket=private-test",
        "storage.r2.public-url=https://public-media.test.invalid",
        "storage.r2.private-read-duration-minutes=2"
})
@Transactional
class PrivateMediaIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RefreshTokenRepository grants;
    @Autowired MatchRequestRepository requests;
    @Autowired BlockedUserRepository blocks;
    @Autowired ChatMessageRepository messages;
    @Autowired ReportRepository reports;
    @Autowired R2Properties storageProperties;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;

    private MockMvc mvc;
    private User sender, receiver, outsider, admin;
    private String senderAuth, receiverAuth, outsiderAuth, adminAuth;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        sender = user("Sender", User.Role.ROLE_USER);
        receiver = user("Receiver", User.Role.ROLE_USER);
        outsider = user("Outsider", User.Role.ROLE_USER);
        admin = user("Admin", User.Role.ROLE_ADMIN);
        senderAuth = token(sender);
        receiverAuth = token(receiver);
        outsiderAuth = token(outsider);
        adminAuth = token(admin);
        requests.saveAndFlush(MatchRequest.builder().sender(sender).receiver(receiver)
                .matchScore(80.0).status(MatchRequest.MatchStatus.ACCEPTED).build());
    }

    @AfterEach void resetState() {
        storageProperties.setPrivateBucket("private-test");
        SecurityContextHolder.clearContext();
    }

    @ParameterizedTest
    @ValueSource(strings = {"chat", "report"})
    void privateUploadTicketNeverIncludesPublicReadUrl(String purpose) throws Exception {
        var result = upload(purpose, senderAuth).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("publicUrl").doesNotExist())
                .andExpect(jsonPath("uploadUrl", containsString("/private-test/")))
                .andExpect(jsonPath("uploadUrl", containsString("X-Amz-Signature=")))
                .andExpect(jsonPath("contentType").value("image/png"));
        String directory = "report".equals(purpose) ? "reports" : "chat";
        assertThat(json(result, "objectKey"))
                .matches(directory + "/" + sender.getId() + "/[0-9a-f-]{36}\\.png");
        assertThat(body(result)).doesNotContain("public-media.test.invalid");
    }

    @ParameterizedTest
    @ValueSource(strings = {"avatar", "room-post"})
    void publicUploadPurposesKeepExistingBucketAndUrl(String purpose) throws Exception {
        upload(purpose, senderAuth).andExpect(status().isOk())
                .andExpect(jsonPath("uploadUrl", containsString("/public-test/")))
                .andExpect(jsonPath("publicUrl", containsString("https://public-media.test.invalid/")));
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "public-test"})
    void missingOrPublicPrivateBucketFailsClosedWithoutBlockingPublicUploads(String privateBucket) throws Exception {
        storageProperties.setPrivateBucket(privateBucket);
        for (String purpose : new String[]{"chat", "report"}) {
            var result = upload(purpose, senderAuth).andExpect(status().isServiceUnavailable());
            assertThat(body(result)).doesNotContain("X-Amz-Signature", "public-media.test.invalid");
        }
        upload("avatar", senderAuth).andExpect(status().isOk());
        assertThat(messages.count()).isZero();
        assertThat(reports.count()).isZero();
    }

    @Test void privateChatStoresOnlyObjectKeyAndGrantsShortReadsToBothParticipants() throws Exception {
        String key = json(upload("chat", senderAuth).andExpect(status().isOk()), "objectKey");
        var sent = send(key, null, senderAuth).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("content").value("Synthetic private photo"));
        assertSigned(json(sent, "imageUrl"), key);
        assertThat(messages.findConversation(sender.getId(), receiver.getId()))
                .singleElement().extracting(ChatMessage::getImageUrl).isEqualTo(key);

        // Existing messages remain readable after a connection ends, unless blocked or locked.
        requests.deleteAll();
        for (String auth : new String[]{senderAuth, receiverAuth}) {
            Long partnerId = auth.equals(senderAuth) ? receiver.getId() : sender.getId();
            var history = conversation(partnerId, auth).andExpect(status().isOk())
                    .andExpect(header().string("Cache-Control", "no-store"))
                    .andExpect(jsonPath("$", hasSize(1)));
            assertSigned(json(history, "$[0].imageUrl"), key);
        }
    }

    @Test void outsiderAndAdminCannotReadAnotherPairsAttachments() throws Exception {
        String key = objectKey("chat", sender);
        savedMessage(key);
        for (String auth : new String[]{outsiderAuth, adminAuth}) {
            for (Long partnerId : new Long[]{sender.getId(), receiver.getId()}) {
                var result = conversation(partnerId, auth).andExpect(status().isOk())
                        .andExpect(jsonPath("$", hasSize(0)));
                assertThat(body(result)).doesNotContain(key, "X-Amz-Signature");
            }
        }
    }

    @ParameterizedTest
    @ValueSource(booleans = {true, false})
    void blockedPairKeepsTextHistoryButReceivesNoNewImageUrls(boolean senderBlocks) throws Exception {
        String key = objectKey("chat", sender);
        savedMessage(key);
        blocks.saveAndFlush(BlockedUser.builder().user(senderBlocks ? sender : receiver)
                .blockedUser(senderBlocks ? receiver : sender).build());
        for (String auth : new String[]{senderAuth, receiverAuth}) {
            Long partnerId = auth.equals(senderAuth) ? receiver.getId() : sender.getId();
            assertHiddenConversation(conversation(partnerId, auth).andExpect(status().isOk()), key);
        }
        send(key, null, senderAuth).andExpect(status().isForbidden());
        assertThat(messages.count()).isEqualTo(1);
    }

    @Test void lockedCounterpartHidesReadUrlsAndLockedTokenCannotReadHistory() throws Exception {
        String key = objectKey("chat", sender);
        savedMessage(key);
        receiver.setStatus("LOCKED");
        users.saveAndFlush(receiver);
        assertHiddenConversation(conversation(receiver.getId(), senderAuth).andExpect(status().isOk()), key);
        conversation(sender.getId(), receiverAuth).andExpect(status().isUnauthorized());
        send(key, null, senderAuth).andExpect(status().isForbidden());
        assertThat(messages.count()).isEqualTo(1);
    }

    @Test void unblockRestoresFreshSignedUrlsWithoutDeletingHistory() throws Exception {
        String key = objectKey("chat", sender);
        savedMessage(key);
        var block = blocks.saveAndFlush(BlockedUser.builder().user(receiver).blockedUser(sender).build());
        assertHiddenConversation(conversation(receiver.getId(), senderAuth).andExpect(status().isOk()), key);
        blocks.delete(block);
        blocks.flush();
        assertSigned(json(conversation(receiver.getId(), senderAuth).andExpect(status().isOk()), "$[0].imageUrl"), key);
        assertThat(messages.count()).isEqualTo(1);
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "https://public-media.test.invalid/chat/1/photo.png",
            "https://images.roommatehub.com/photo.jpg",
            "https://attacker.test.invalid/pixel.png",
            "/uploads/photo.png",
            "chat/1/photo.png"
    })
    void legacyImageUrlInputIsRejectedEvenForFormerlyTrustedHosts(String legacyUrl) throws Exception {
        send(null, legacyUrl, senderAuth).andExpect(status().isBadRequest());
        assertThat(messages.count()).isZero();
    }

    @Test void legacyUrlCannotBypassValidationAlongsideValidPrivateKey() throws Exception {
        send(objectKey("chat", sender), "https://public-media.test.invalid/photo.png", senderAuth)
                .andExpect(status().isBadRequest());
        assertThat(messages.count()).isZero();
    }

    @Test void privateChatRejectsForeignOwnerAndReportPurposeWithoutPersisting() throws Exception {
        for (String key : new String[]{objectKey("chat", receiver), objectKey("reports", sender)}) {
            send(key, null, senderAuth).andExpect(status().isForbidden());
        }
        assertThat(messages.count()).isZero();
    }

    @Test void privateChatRejectsMalformedKeysAndCannotCreatePrivateMediaWithoutPrivateBucket() throws Exception {
        for (String key : new String[]{"chat/" + sender.getId() + "/../secret.png",
                "chat/" + sender.getId() + "/photo.png", "https://r2.test.invalid/file.png"}) {
            send(key, null, senderAuth).andExpect(status().isForbidden());
        }
        storageProperties.setPrivateBucket("");
        send(objectKey("chat", sender), null, senderAuth).andExpect(status().isServiceUnavailable());
        assertThat(messages.count()).isZero();
    }

    @ParameterizedTest
    @ValueSource(strings = {"https://public-media.test.invalid/chat/1/legacy.png", "/uploads/legacy.jpg"})
    void oldPublicChatLinksAreNotReturnedEvenToAuthorizedParticipants(String legacyUrl) throws Exception {
        savedMessage(legacyUrl);
        assertHiddenConversation(conversation(receiver.getId(), senderAuth).andExpect(status().isOk()), legacyUrl);
        assertHiddenConversation(conversation(sender.getId(), receiverAuth).andExpect(status().isOk()), legacyUrl);
        assertThat(messages.findAll()).singleElement().extracting(ChatMessage::getImageUrl).isEqualTo(legacyUrl);
    }

    @Test void corruptStoredChatOwnerOrPurposeIsNotSigned() throws Exception {
        for (String key : new String[]{objectKey("chat", receiver), objectKey("reports", sender)}) {
            savedMessage(key);
        }
        var result = conversation(receiver.getId(), senderAuth).andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].imageUrl").doesNotExist())
                .andExpect(jsonPath("$[1].imageUrl").doesNotExist());
        assertThat(body(result)).doesNotContain("X-Amz-Signature", "private-test");
    }

    @Test void reportEvidenceStoresKeyAndOnlyAdminReceivesSignedListAndModerationResponse() throws Exception {
        String key = json(upload("report", senderAuth).andExpect(status().isOk()), "objectKey");
        var submitted = report(key, senderAuth).andExpect(status().isOk());
        assertThat(body(submitted)).doesNotContain(key, "evidenceUrl", "X-Amz-Signature", "public-media.test.invalid");
        Report saved = reports.findByReporterIdOrderByCreatedAtDesc(sender.getId()).getFirst();
        assertThat(saved.getEvidenceUrl()).isEqualTo(key);
        for (String auth : new String[]{senderAuth, receiverAuth, outsiderAuth}) {
            mvc.perform(get("/api/v1/admin/reports").header("Authorization", auth))
                    .andExpect(status().isForbidden());
            mvc.perform(put("/api/v1/admin/reports/{id}/moderate", saved.getId())
                    .header("Authorization", auth).param("status", "RESOLVED"))
                    .andExpect(status().isForbidden());
        }
        var listed = mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$", hasSize(1)));
        assertSigned(json(listed, "$[0].evidenceUrl"), key);
        var moderated = mvc.perform(put("/api/v1/admin/reports/{id}/moderate", saved.getId())
                .header("Authorization", adminAuth).param("status", "RESOLVED").param("note", "Test-only review"))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("status").value("RESOLVED"));
        assertSigned(json(moderated, "evidenceUrl"), key);
        assertThat(reports.findById(saved.getId()).orElseThrow().getEvidenceUrl()).isEqualTo(key);
    }

    @Test void reportEvidenceRejectsForeignOwnerChatPurposeAndMalformedKeysWithoutPersisting() throws Exception {
        for (String key : new String[]{objectKey("reports", receiver), objectKey("chat", sender),
                "reports/" + sender.getId() + "/../secret.png", "https://public-media.test.invalid/report.png"}) {
            report(key, senderAuth).andExpect(status().isForbidden());
        }
        assertThat(reports.count()).isZero();
    }

    @Test void reportEvidenceFailsClosedIfPrivateBucketMissingButTextOnlyReportWorks() throws Exception {
        storageProperties.setPrivateBucket("");
        report(objectKey("reports", sender), senderAuth).andExpect(status().isServiceUnavailable());
        assertThat(reports.count()).isZero();
        report(null, senderAuth).andExpect(status().isOk());
        assertThat(reports.findAll()).singleElement().extracting(Report::getEvidenceUrl).isNull();
    }

    @Test void unavailablePrivateStorageKeepsChatAndReportMetadataWithoutPublicFallback() throws Exception {
        String chatKey = objectKey("chat", sender);
        savedMessage(chatKey);
        String reportKey = objectKey("reports", sender);
        reports.saveAndFlush(Report.builder().reporter(sender).targetId(receiver.getId())
                .targetType("USER").reason("Synthetic report").evidenceUrl(reportKey).build());
        storageProperties.setPrivateBucket("");
        assertHiddenConversation(conversation(receiver.getId(), senderAuth).andExpect(status().isOk()), chatKey);
        var result = mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].reason").value("Synthetic report"))
                .andExpect(jsonPath("$[0].evidenceUrl").doesNotExist());
        assertThat(body(result)).doesNotContain(reportKey, "X-Amz-Signature", "public-media.test.invalid");
        assertThat(reports.findAll()).singleElement().extracting(Report::getEvidenceUrl).isEqualTo(reportKey);
    }

    @Test void adminCanStillReviewEvidenceWhenReporterIsLocked() throws Exception {
        String key = objectKey("reports", sender);
        reports.saveAndFlush(Report.builder().reporter(sender).targetId(receiver.getId())
                .targetType("USER").reason("Synthetic report").evidenceUrl(key).build());
        sender.setStatus("LOCKED");
        users.saveAndFlush(sender);
        var result = mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(1)));
        assertSigned(json(result, "$[0].evidenceUrl"), key);
    }

    @Test void oldPublicOrCorruptReportEvidenceIsNotReturnedToAdmin() throws Exception {
        for (String value : new String[]{"https://public-media.test.invalid/reports/legacy.jpg",
                objectKey("chat", sender), objectKey("reports", receiver)}) {
            Report report = reports.saveAndFlush(Report.builder().reporter(sender).targetId(receiver.getId())
                    .targetType("USER").reason("Synthetic report").evidenceUrl(value).build());
            mvc.perform(put("/api/v1/admin/reports/{id}/moderate", report.getId())
                    .header("Authorization", adminAuth).param("status", "RESOLVED"))
                    .andExpect(status().isOk()).andExpect(jsonPath("evidenceUrl").doesNotExist());
        }
        var result = mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(3)));
        for (int i = 0; i < 3; i++) {
            result.andExpect(jsonPath("$[" + i + "].evidenceUrl").doesNotExist());
        }
        assertThat(body(result)).doesNotContain("public-media.test.invalid", "X-Amz-Signature", "private-test");
    }

    @Test void anonymousAndLockedAdminCannotObtainPrivateEvidence() throws Exception {
        savedMessage(objectKey("chat", sender));
        mvc.perform(get("/api/v1/chat/messages/{id}", receiver.getId())).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/admin/reports")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/uploads/presign").contentType("application/json")
                .content(uploadBody("chat"))).andExpect(status().isUnauthorized());
        admin.setStatus("LOCKED");
        users.saveAndFlush(admin);
        mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isUnauthorized());
    }

    @Test void rawDtoMappingNeverExposesStoredKeysOrLegacyUrls() {
        for (String value : new String[]{objectKey("chat", sender), "https://public-media.test.invalid/old.jpg"}) {
            var message = savedMessage(value);
            assertThat(ChatMessageDTO.from(message, sender.getId()).getImageUrl()).isNull();
            var report = Report.builder().reporter(sender).targetId(receiver.getId()).targetType("USER")
                    .reason("Synthetic report").evidenceUrl(value).build();
            assertThat(AdminReportResponseDTO.from(report).getEvidenceUrl()).isNull();
        }
    }

    private ResultActions upload(String purpose, String auth) throws Exception {
        return mvc.perform(post("/api/v1/uploads/presign").header("Authorization", auth)
                .contentType("application/json").content(uploadBody(purpose)));
    }

    private String uploadBody(String purpose) {
        return "{\"fileName\":\"test.png\",\"contentType\":\"image/png\",\"fileSize\":120,\"purpose\":\""
                + purpose + "\"}";
    }

    private ResultActions send(String key, String legacyUrl, String auth) throws Exception {
        String body = "{\"receiverId\":" + receiver.getId() + ",\"content\":\"Synthetic private photo\""
                + (key == null ? "" : ",\"imageObjectKey\":\"" + key + "\"")
                + (legacyUrl == null ? "" : ",\"imageUrl\":\"" + legacyUrl + "\"") + "}";
        return mvc.perform(post("/api/v1/chat/messages").header("Authorization", auth)
                .contentType("application/json").content(body));
    }

    private ResultActions conversation(Long partnerId, String auth) throws Exception {
        return mvc.perform(get("/api/v1/chat/messages/{id}", partnerId).header("Authorization", auth));
    }

    private ResultActions report(String key, String auth) throws Exception {
        String body = "{\"targetId\":" + receiver.getId()
                + ",\"targetType\":\"USER\",\"reason\":\"Synthetic test evidence\""
                + (key == null ? "" : ",\"evidenceObjectKey\":\"" + key + "\"") + "}";
        return mvc.perform(post("/api/v1/reports").header("Authorization", auth)
                .contentType("application/json").content(body));
    }

    private void assertHiddenConversation(ResultActions result, String storedValue) throws Exception {
        result.andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].content").value("Synthetic private photo"))
                .andExpect(jsonPath("$[0].imageUrl").doesNotExist());
        assertThat(body(result)).doesNotContain(storedValue, "X-Amz-Signature", "public-media.test.invalid");
    }

    private void assertSigned(String url, String key) {
        URI parsed = URI.create(url);
        assertThat(parsed.getScheme()).isEqualTo("https");
        assertThat(parsed.getHost()).isEqualTo("r2.test.invalid");
        assertThat(parsed.getPath()).isEqualTo("/private-test/" + key);
        assertThat(parsed.getQuery()).contains("X-Amz-Signature=", "X-Amz-Expires=120");
        assertThat(url).doesNotContain("public-media.test.invalid");
    }

    private String json(ResultActions result, String path) throws Exception {
        return JsonPath.read(body(result), path.startsWith("$") ? path : "$." + path);
    }

    private String body(ResultActions result) throws Exception {
        return result.andReturn().getResponse().getContentAsString();
    }

    private String objectKey(String directory, User owner) {
        return directory + "/" + owner.getId() + "/" + UUID.randomUUID() + ".png";
    }

    private ChatMessage savedMessage(String value) {
        return messages.saveAndFlush(ChatMessage.builder().sender(sender).receiver(receiver)
                .content("Synthetic private photo").imageUrl(value).build());
    }

    private User user(String name, User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE").role(role).build());
    }

    private String token(User user) {
        var grant = grants.saveAndFlush(RefreshToken.builder().user(user).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }
}
