package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AccountLockIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired ChatMessageRepository messages;
    @Autowired MatchRequestRepository matches;
    @Autowired JwtUtils jwtUtils;
    @Autowired WebApplicationContext webContext;
    @Autowired FilterChainProxy securityFilterChain;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(webContext).addFilters(securityFilterChain).build();
    }

    @AfterEach void clearAuthentication() { SecurityContextHolder.clearContext(); }

    @Test void adminCannotLockSelfThroughAnySupportedAlias() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN);
        String authorization = bearer(admin);
        for (String suffix : new String[]{"status", "toggle-status"}) {
            String route = "/api/v1/admin/users/" + admin.getId() + "/" + suffix;
            mvc.perform(put(route).header("Authorization", authorization)).andExpect(status().isForbidden());
            mvc.perform(patch(route).header("Authorization", authorization)).andExpect(status().isForbidden());
            assertThat(users.findById(admin.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
        }
    }

    @Test void onlyAdminCanToggleAnotherAccountAndLockedAccessIsRejected() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        String hostToken = bearer(host);
        mvc.perform(patch("/api/v1/admin/users/{id}/status", admin.getId())
                .header("Authorization", hostToken)).andExpect(status().isForbidden());
        toggle(admin, host, "LOCKED");
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", hostToken))
                .andExpect(status().isUnauthorized());
        toggle(admin, host, "ACTIVE");
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", bearer(host)))
                .andExpect(status().isOk());
    }

    @Test void lockedHostPostsAreHiddenButAdminHistoryAndPostStatusesArePreserved() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        RoomPost approved = room(host, RoomPost.PostStatus.APPROVED);
        RoomPost available = room(host, RoomPost.PostStatus.AVAILABLE);
        RoomPost pending = room(host, RoomPost.PostStatus.PENDING);
        RoomPost closed = room(host, RoomPost.PostStatus.CLOSED);
        RoomPost rejected = room(host, RoomPost.PostStatus.REJECTED);
        RoomPost other = room(user("Other", User.Role.ROLE_USER), RoomPost.PostStatus.APPROVED);
        assertPublicVisibility(approved, true);
        assertPublicVisibility(available, true);
        assertAdminVisibility(admin, approved, true);
        assertAdminVisibility(admin, available, true);
        assertAdminVisibility(admin, pending, false);
        assertAdminVisibility(admin, closed, false);
        assertAdminVisibility(admin, rejected, false);

        toggle(admin, host, "LOCKED");
        assertPublicVisibility(approved, false);
        assertPublicVisibility(available, false);
        assertPublicVisibility(other, true);
        assertAdminVisibility(admin, approved, false);
        assertAdminVisibility(admin, available, false);
        assertAdminVisibility(admin, other, true);
        mvc.perform(get("/api/v1/admin/posts").header("Authorization", bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(approved.getId().intValue())))
                .andExpect(jsonPath("$[*].id", hasItem(pending.getId().intValue())));
        assertThat(posts.findById(approved.getId()).orElseThrow().getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
        assertThat(posts.findById(available.getId()).orElseThrow().getStatus()).isEqualTo(RoomPost.PostStatus.AVAILABLE);

        toggle(admin, host, "ACTIVE");
        assertPublicVisibility(approved, true);
        assertPublicVisibility(available, true);
        assertPublicVisibility(pending, false);
        assertPublicVisibility(closed, false);
        assertAdminVisibility(admin, approved, true);
        assertAdminVisibility(admin, available, true);
        assertAdminVisibility(admin, pending, false);
        assertAdminVisibility(admin, closed, false);
        assertAdminVisibility(admin, rejected, false);
        mvc.perform(get("/api/v1/posts/my").header("Authorization", bearer(host)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(5));
    }

    @Test void lockedMatchedReceiverCannotReceiveChatAndUnlockRestoresSending() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), receiver = user("Receiver", User.Role.ROLE_USER);
        User sender = user("Sender", User.Role.ROLE_USER);
        MatchRequest match = matches.saveAndFlush(MatchRequest.builder().sender(sender).receiver(receiver)
                .matchScore(85.0).status(MatchRequest.MatchStatus.ACCEPTED).build());

        assertChatLockLifecycle(admin, sender, receiver);

        assertThat(matches.findById(match.getId()).orElseThrow().getStatus())
                .isEqualTo(MatchRequest.MatchStatus.ACCEPTED);
    }

    @Test void lockedAppointmentHostCannotReceiveChatAndUnlockRestoresSending() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        User viewer = user("Viewer", User.Role.ROLE_USER);
        ViewingAppointment appointment = appointments.saveAndFlush(ViewingAppointment.builder()
                .requester(viewer).host(host).roomPost(room(host, RoomPost.PostStatus.APPROVED))
                .appointmentTime(OffsetDateTime.now().plusDays(2))
                .status(ViewingAppointment.AppointmentStatus.CONFIRMED).build());

        assertChatLockLifecycle(admin, viewer, host);

        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CONFIRMED);
    }

    private void assertChatLockLifecycle(User admin, User sender, User receiver) throws Exception {
        String authorization = bearer(sender);
        String body = "{\"receiverId\":" + receiver.getId() + ",\"content\":\"Chat lock regression\"}";
        long before = messages.count();
        mvc.perform(post("/api/v1/chat/messages").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isOk());
        assertThat(messages.count()).isEqualTo(before + 1);

        toggle(admin, receiver, "LOCKED");
        mvc.perform(post("/api/v1/chat/messages").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        assertThat(messages.count()).isEqualTo(before + 1);
        mvc.perform(get("/api/v1/chat/messages/{id}", receiver.getId()).header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1));

        toggle(admin, receiver, "ACTIVE");
        mvc.perform(post("/api/v1/chat/messages").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isOk());
        assertThat(messages.count()).isEqualTo(before + 2);
    }

    private void assertAdminVisibility(User admin, RoomPost post, boolean visible) throws Exception {
        mvc.perform(get("/api/v1/admin/posts").header("Authorization", bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + post.getId() + ")].publiclyVisible", hasItem(visible)));
    }

    @Test void lockedHostCannotReceiveNewAppointmentsAndUnlockAllowsThemAgain() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        User viewer = user("Viewer", User.Role.ROLE_USER);
        RoomPost post = room(host, RoomPost.PostStatus.APPROVED);
        long countBefore = appointments.count();
        toggle(admin, host, "LOCKED");
        mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(viewer))
                .contentType(MediaType.APPLICATION_JSON).content(appointmentBody(post)))
                .andExpect(status().isForbidden());
        assertThat(appointments.count()).isEqualTo(countBefore);
        toggle(admin, host, "ACTIVE");
        mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(viewer))
                .contentType(MediaType.APPLICATION_JSON).content(appointmentBody(post)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("PENDING"));
        assertThat(appointments.count()).isEqualTo(countBefore + 1);
    }

    @Test void lockingHostRetainsExistingAppointmentsAndRequesterCanStillCancel() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        User viewer = user("Viewer", User.Role.ROLE_USER);
        RoomPost post = room(host, RoomPost.PostStatus.APPROVED);
        ViewingAppointment existing = appointments.saveAndFlush(ViewingAppointment.builder()
                .requester(viewer).host(host).roomPost(post).appointmentTime(OffsetDateTime.now().plusDays(2))
                .status(ViewingAppointment.AppointmentStatus.CONFIRMED).build());
        toggle(admin, host, "LOCKED");
        assertThat(appointments.findById(existing.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CONFIRMED);
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", bearer(viewer)))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(existing.getId()));
        mvc.perform(put("/api/v1/appointments/{id}/status", existing.getId())
                .header("Authorization", bearer(viewer)).param("status", "CANCELLED"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test void lockedHostPostCannotBeSavedButOldBookmarkCanBeRemoved() throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), host = user("Host", User.Role.ROLE_USER);
        User viewer = user("Viewer", User.Role.ROLE_USER);
        RoomPost post = room(host, RoomPost.PostStatus.AVAILABLE);
        String route = "/api/v1/profile/saved-posts/" + post.getId();
        mvc.perform(put(route).header("Authorization", bearer(viewer)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"saved\":true}")).andExpect(status().isOk());
        toggle(admin, host, "LOCKED");
        mvc.perform(put(route).header("Authorization", bearer(viewer)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"saved\":true}")).andExpect(status().isNotFound());
        assertThat(users.findById(viewer.getId()).orElseThrow().getSavedPostIds()).contains(post.getId());
        mvc.perform(put(route).header("Authorization", bearer(viewer)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"saved\":false}")).andExpect(status().isOk());
        assertThat(users.findById(viewer.getId()).orElseThrow().getSavedPostIds()).doesNotContain(post.getId());
    }

    private void assertPublicVisibility(RoomPost post, boolean visible) throws Exception {
        var ids = hasItem(post.getId().intValue());
        mvc.perform(get("/api/v1/posts")).andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", visible ? ids : not(ids)));
        mvc.perform(get("/api/v1/posts/{id}", post.getId()))
                .andExpect(visible ? status().isOk() : status().isNotFound());
    }

    private void toggle(User admin, User target, String expected) throws Exception {
        mvc.perform(patch("/api/v1/admin/users/{id}/status", target.getId()).header("Authorization", bearer(admin)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value(expected));
        users.flush();
    }

    private String appointmentBody(RoomPost post) {
        return "{\"roomPostId\":" + post.getId() + ",\"appointmentTime\":\""
                + OffsetDateTime.now().plusDays(3) + "\",\"note\":\"Local regression test\"}";
    }

    private RoomPost room(User author, RoomPost.PostStatus status) {
        return posts.saveAndFlush(RoomPost.builder().author(author).title("Test room").description("Test description")
                .price(2000000.0).address("Test address").maxOccupants(2).status(status).build());
    }

    private User user(String name, User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .passwordHash("test-only-placeholder").fullName(name).gender("MALE").role(role).build());
    }

    private String bearer(User user) {
        RefreshToken grant = refreshTokens.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(7)).build());
        return "Bearer " + jwtUtils.generateToken(user.getEmail(), user.getId(), grant.getId());
    }
}
