package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.Report;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Real controllers, JWT filter and local H2 transactions; no external database, R2 or email requests.
@SpringBootTest
@Transactional
class ApiBusinessErrorIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RefreshTokenRepository grants;
    @Autowired RoomPostRepository posts;
    @Autowired ReportRepository reports;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired MatchRequestRepository matches;
    @Autowired PasswordEncoder encoder;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;

    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }

    @AfterEach void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test void moderatingMissingPostIsNotFoundWithoutCreatingOrChangingData() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN);
        RoomPost existing = room(user("Host", User.Role.ROLE_USER));
        long count = posts.count();

        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", Long.MAX_VALUE)
                        .header("Authorization", bearer(admin)).param("status", "APPROVED"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("status").value(404))
                .andExpect(jsonPath("message").value("Bài đăng không tồn tại!"));

        assertThat(posts.count()).isEqualTo(count);
        assertPending(existing);
    }

    @Test void missingAdminUserAndReportRemainNotFound() throws Exception {
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));
        long userCount = users.count(), reportCount = reports.count();

        mvc.perform(get("/api/v1/admin/users/{id}", Long.MAX_VALUE).header("Authorization", auth))
                .andExpect(status().isNotFound()).andExpect(jsonPath("status").value(404));
        mvc.perform(put("/api/v1/admin/reports/{id}/moderate", Long.MAX_VALUE)
                        .header("Authorization", auth).param("status", "RESOLVED"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("status").value(404));

        assertThat(users.count()).isEqualTo(userCount);
        assertThat(reports.count()).isEqualTo(reportCount);
    }

    @Test void invalidPathIdsAreBadRequestsRatherThanInternalServerErrors() throws Exception {
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));
        long postCount = posts.count(), appointmentCount = appointments.count();
        for (String id : new String[]{"not-a-number", "9223372036854775808"}) {
            mvc.perform(get("/api/v1/posts/{id}", id))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
            mvc.perform(get("/api/v1/admin/users/{id}", id).header("Authorization", auth))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
            mvc.perform(put("/api/v1/appointments/{id}/status", id)
                            .header("Authorization", auth).param("status", "CANCELLED"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
        }
        assertThat(posts.count()).isEqualTo(postCount);
        assertThat(appointments.count()).isEqualTo(appointmentCount);
    }

    @Test void missingRequiredQueryParameterIsBadRequestAndDoesNotModeratePost() throws Exception {
        RoomPost existing = room(user("Host", User.Role.ROLE_USER));
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));

        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", existing.getId())
                        .header("Authorization", auth))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));

        assertPending(existing);
    }

    @Test void malformedDateQueryDoesNotChangeAccountFields() throws Exception {
        User current = user("Unchanged name", User.Role.ROLE_USER);
        LocalDate initialBirthDate = LocalDate.of(2000, 1, 2);
        current.setBirthDate(initialBirthDate);
        users.saveAndFlush(current);
        String auth = bearer(current);

        for (String birthDate : new String[]{"not-a-date", "2000-99-40"}) {
            mvc.perform(put("/api/v1/profile/user/{id}", current.getId())
                            .header("Authorization", auth).param("fullName", "Must not persist")
                            .param("phone", "").param("gender", "MALE").param("birthDate", birthDate))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
            User unchanged = users.findById(current.getId()).orElseThrow();
            assertThat(unchanged.getFullName()).isEqualTo("Unchanged name");
            assertThat(unchanged.getBirthDate()).isEqualTo(initialBirthDate);
        }
    }

    @Test void invalidQueryNumbersAndBooleansAreBadRequests() throws Exception {
        String auth = bearer(user("User", User.Role.ROLE_USER));
        long matchCount = matches.count();
        mvc.perform(post("/api/v1/matches/requests").header("Authorization", auth)
                        .param("receiverId", "invalid"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
        assertThat(matches.count()).isEqualTo(matchCount);
        mvc.perform(put("/api/v1/matches/requests/1/respond").header("Authorization", auth)
                        .param("accept", "invalid"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
        assertThat(matches.count()).isEqualTo(matchCount);
    }

    @Test void invalidModerationStatusesNeverAlterPostsOrReports() throws Exception {
        User host = user("Host", User.Role.ROLE_USER);
        RoomPost existing = room(host);
        Report report = reports.saveAndFlush(Report.builder().reporter(host).targetId(existing.getId())
                .targetType("POST").reason("Synthetic report").actionNote("Original note").build());
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));

        for (String invalid : new String[]{"UNKNOWN", "PENDING", " "}) {
            mvc.perform(put("/api/v1/admin/posts/{id}/moderate", existing.getId())
                            .header("Authorization", auth).param("status", invalid).param("reason", "Must not persist"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
            assertPending(existing);
        }
        mvc.perform(put("/api/v1/admin/reports/{id}/moderate", report.getId())
                        .header("Authorization", auth).param("status", "UNKNOWN").param("note", "Must not persist"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
        Report unchanged = reports.findById(report.getId()).orElseThrow();
        assertThat(unchanged.getStatus()).isEqualTo("PENDING");
        assertThat(unchanged.getActionNote()).isEqualTo("Original note");
    }

    @Test void securityChecksPrecedeInvalidAdminInputAndNeverMutatePosts() throws Exception {
        RoomPost existing = room(user("Host", User.Role.ROLE_USER));
        String ordinaryAuth = bearer(user("Ordinary user", User.Role.ROLE_USER));
        mvc.perform(put("/api/v1/admin/posts/not-a-number/moderate").param("status", "APPROVED"))
                .andExpect(status().isUnauthorized());
        mvc.perform(put("/api/v1/admin/posts/not-a-number/moderate")
                        .header("Authorization", ordinaryAuth).param("status", "APPROVED"))
                .andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", existing.getId())
                        .header("Authorization", ordinaryAuth).param("status", "APPROVED"))
                .andExpect(status().isForbidden());
        assertPending(existing);
    }

    @Test void unsupportedRoutesMethodsAndContentTypesKeepTheirFrameworkStatuses() throws Exception {
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));
        long postCount = posts.count();
        mvc.perform(get("/api/v1/unknown-group-six-route").header("Authorization", auth))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/admin/users").header("Authorization", auth))
                .andExpect(status().isMethodNotAllowed()).andExpect(header().string("Allow", containsString("GET")));
        mvc.perform(post("/api/v1/posts").header("Authorization", auth)
                        .contentType(MediaType.TEXT_PLAIN).content("unsupported-body"))
                .andExpect(status().isUnsupportedMediaType());
        assertThat(posts.count()).isEqualTo(postCount);
    }

    @Test void malformedJsonIsBadRequestWithoutCreatingAppointment() throws Exception {
        String auth = bearer(user("User", User.Role.ROLE_USER));
        long appointmentCount = appointments.count();
        mvc.perform(post("/api/v1/appointments").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"postId\":"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400));
        assertThat(appointments.count()).isEqualTo(appointmentCount);
    }

    @Test void duplicateRegistrationIsConflictWithoutNewUserOrSession() throws Exception {
        User existing = user("Existing account", User.Role.ROLE_USER);
        long userCount = users.count(), grantCount = grants.count();
        String body = """
                {"email":"%s","password":"%s","fullName":"New account","gender":"MALE",
                 "birthDate":"2000-01-01","university":"Test university"}
                """.formatted(existing.getEmail(), UUID.randomUUID());

        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict()).andExpect(jsonPath("status").value(409))
                .andExpect(jsonPath("message").value("Email đã được đăng ký!"));

        assertThat(users.count()).isEqualTo(userCount);
        assertThat(grants.count()).isEqualTo(grantCount);
        assertThat(users.findById(existing.getId()).orElseThrow().getFullName()).isEqualTo("Existing account");
    }

    @Test void wrongCurrentPasswordIsBadRequestWithoutChangingPasswordOrRevokingSession() throws Exception {
        User current = user("User", User.Role.ROLE_USER);
        current.setPasswordHash(encoder.encode(UUID.randomUUID().toString()));
        users.saveAndFlush(current);
        String originalHash = current.getPasswordHash(), auth = bearer(current);
        long grantCount = grants.count();
        String body = "{\"oldPassword\":\"" + UUID.randomUUID() + "\",\"newPassword\":\"" + UUID.randomUUID() + "\"}";

        mvc.perform(put("/api/v1/auth/change-password").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400))
                .andExpect(jsonPath("message").value("Mật khẩu hiện tại không chính xác!"));

        User unchanged = users.findById(current.getId()).orElseThrow();
        assertThat(unchanged.getPasswordHash()).isEqualTo(originalHash);
        assertThat(unchanged.getPasswordChangedAt()).isNull();
        assertThat(grants.count()).isEqualTo(grantCount);
        mvc.perform(get("/api/v1/profile/search-status").header("Authorization", auth)).andExpect(status().isOk());
    }

    @Test void successfulModerationStillPublishesActualPost() throws Exception {
        RoomPost existing = room(user("Host", User.Role.ROLE_USER));
        String auth = bearer(user("Admin", User.Role.ROLE_ADMIN));
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", existing.getId())
                        .header("Authorization", auth).param("status", "APPROVED").param("reason", "Reviewed"))
                .andExpect(status().isOk()).andExpect(jsonPath("status").value("APPROVED"));
        assertThat(posts.findById(existing.getId()).orElseThrow().getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
        mvc.perform(get("/api/v1/posts/{id}", existing.getId()))
                .andExpect(status().isOk()).andExpect(jsonPath("id").value(existing.getId()));
    }

    private void assertPending(RoomPost existing) {
        RoomPost unchanged = posts.findById(existing.getId()).orElseThrow();
        assertThat(unchanged.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
        assertThat(unchanged.getModerationReason()).isNull();
    }

    private RoomPost room(User author) {
        return posts.saveAndFlush(RoomPost.builder().author(author).title("Synthetic room")
                .description("Synthetic description").price(2_000_000.0).address("Synthetic address")
                .district("Thủ Đức").maxOccupants(2).status(RoomPost.PostStatus.PENDING).build());
    }

    private String bearer(User user) {
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private User user(String name, User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE").role(role).build());
    }
}
