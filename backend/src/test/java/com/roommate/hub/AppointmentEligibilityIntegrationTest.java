package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.BlockedUser;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
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

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.UUID;

import static com.roommate.hub.entity.ViewingAppointment.AppointmentStatus.COMPLETED;
import static com.roommate.hub.entity.ViewingAppointment.AppointmentStatus.CONFIRMED;
import static com.roommate.hub.entity.ViewingAppointment.AppointmentStatus.PENDING;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class AppointmentEligibilityIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired MatchRequestRepository matches;
    @Autowired BlockedUserRepository blocks;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;

    private MockMvc mvc;
    private User requester, host, outsider;
    private String requesterAuth, hostAuth, outsiderAuth;
    private RoomPost room;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        requester = user("Eligibility requester");
        host = user("Eligibility host");
        outsider = user("Eligibility outsider");
        requesterAuth = token(requester);
        hostAuth = token(host);
        outsiderAuth = token(outsider);
        room = posts.saveAndFlush(RoomPost.builder().author(host).title("Eligibility test room")
                .description("Synthetic test room").address("Synthetic test address").price(2500000.0)
                .maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
    }

    @AfterEach void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @ParameterizedTest
    @EnumSource(value = RoomPost.PostStatus.class, names = {"APPROVED", "AVAILABLE"})
    void activeUnblockedPairCanCreateConfirmRepeatAndCompleteOpenRoom(RoomPost.PostStatus roomStatus)
            throws Exception {
        room.setStatus(roomStatus);
        posts.saveAndFlush(room);
        create(requesterAuth).andExpect(status().isOk()).andExpect(jsonPath("status").value("PENDING"));
        var appointment = appointments.findAllByUserId(requester.getId()).getFirst();
        update(appointment, hostAuth, CONFIRMED).andExpect(status().isOk());
        update(appointment, hostAuth, CONFIRMED).andExpect(status().isOk());
        update(appointment, hostAuth, COMPLETED).andExpect(status().isOk());
        assertPersistedStatus(appointment, COMPLETED);
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void creationRejectsEitherBlockingDirectionEvenWithAcceptedConnection(boolean hostBlocks) throws Exception {
        acceptedConnection();
        block(hostBlocks);
        long before = appointments.count();
        create(requesterAuth).andExpect(status().isForbidden());
        assertThat(appointments.count()).isEqualTo(before);
    }

    @Test void creationRejectsLockedHostWithoutSavingAppointment() throws Exception {
        host.setStatus("LOCKED");
        users.saveAndFlush(host);
        long before = appointments.count();
        create(requesterAuth).andExpect(status().isForbidden());
        assertThat(appointments.count()).isEqualTo(before);
    }

    @ParameterizedTest
    @EnumSource(value = RoomPost.PostStatus.class, names = {"PENDING", "REJECTED", "CLOSED"})
    void creationRejectsRoomThatIsNotOpenWithoutSavingAppointment(RoomPost.PostStatus roomStatus) throws Exception {
        room.setStatus(roomStatus);
        posts.saveAndFlush(room);
        long before = appointments.count();
        create(requesterAuth).andExpect(status().isBadRequest());
        assertThat(appointments.count()).isEqualTo(before);
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void hostCannotConfirmRepeatConfirmationOrCompleteAfterEitherSideBlocks(boolean hostBlocks) throws Exception {
        acceptedConnection();
        block(hostBlocks);
        assertHostOperationsDenied(403);
    }

    @Test void activeHostCannotConfirmRepeatConfirmationOrCompleteAfterRequesterIsLocked() throws Exception {
        requester.setStatus("LOCKED");
        users.saveAndFlush(requester);
        assertHostOperationsDenied(403);
    }

    @ParameterizedTest
    @EnumSource(value = RoomPost.PostStatus.class, names = {"PENDING", "REJECTED", "CLOSED"})
    void hostCannotConfirmRepeatConfirmationOrCompleteAfterRoomStopsBeingOpen(RoomPost.PostStatus roomStatus)
            throws Exception {
        room.setStatus(roomStatus);
        posts.saveAndFlush(room);
        assertHostOperationsDenied(400);
    }

    @ParameterizedTest
    @ValueSource(strings = {"REQUESTER_BLOCKS", "HOST_BLOCKS", "REQUESTER_LOCKED", "HOST_LOCKED", "ROOM_CLOSED"})
    void activeParticipantCanStillCancelPendingOrConfirmedHistoryWhenEligibilityIsRevoked(String condition)
            throws Exception {
        if (condition.equals("REQUESTER_BLOCKS")) block(false);
        if (condition.equals("HOST_BLOCKS")) block(true);
        if (condition.equals("REQUESTER_LOCKED")) {
            requester.setStatus("LOCKED");
            users.saveAndFlush(requester);
        }
        if (condition.equals("HOST_LOCKED")) {
            host.setStatus("LOCKED");
            users.saveAndFlush(host);
        }
        if (condition.equals("ROOM_CLOSED")) {
            room.setStatus(RoomPost.PostStatus.CLOSED);
            posts.saveAndFlush(room);
        }
        // A locked caller has no valid authentication; the still-active counterpart cancels.
        String[] cancellationAuthorizations = switch (condition) {
            case "REQUESTER_LOCKED" -> new String[]{hostAuth};
            case "HOST_LOCKED" -> new String[]{requesterAuth};
            default -> new String[]{requesterAuth, hostAuth};
        };
        for (String authorization : cancellationAuthorizations) {
            for (var initial : new ViewingAppointment.AppointmentStatus[]{PENDING, CONFIRMED}) {
                var appointment = appointment(initial);
                assertPersistedStatus(appointment, initial);
                update(appointment, authorization, ViewingAppointment.AppointmentStatus.CANCELLED)
                        .andExpect(status().isOk()).andExpect(jsonPath("status").value("CANCELLED"));
                assertPersistedStatus(appointment, ViewingAppointment.AppointmentStatus.CANCELLED);
            }
        }
        int expectedHistorySize = cancellationAuthorizations.length * 2;
        for (String authorization : cancellationAuthorizations) {
            mvc.perform(get("/api/v1/appointments/my").header("Authorization", authorization))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(expectedHistorySize));
        }
        assertThat(appointments.findAllByUserId(requester.getId())).hasSize(expectedHistorySize)
                .extracting(ViewingAppointment::getStatus)
                .containsOnly(ViewingAppointment.AppointmentStatus.CANCELLED);
    }

    @ParameterizedTest
    @EnumSource(value = ViewingAppointment.AppointmentStatus.class, names = {"CONFIRMED", "COMPLETED"})
    void requesterCannotConfirmIncludingSameStatusOrComplete(ViewingAppointment.AppointmentStatus target)
            throws Exception {
        var appointment = appointment(CONFIRMED);
        update(appointment, requesterAuth, target).andExpect(status().isForbidden());
        assertPersistedStatus(appointment, CONFIRMED);
    }

    @ParameterizedTest
    @EnumSource(value = ViewingAppointment.AppointmentStatus.class, names = {"CANCELLED", "COMPLETED"})
    void terminalAppointmentCannotBeChangedEvenByHost(ViewingAppointment.AppointmentStatus initial) throws Exception {
        var appointment = appointment(initial);
        for (var target : ViewingAppointment.AppointmentStatus.values()) {
            update(appointment, hostAuth, target).andExpect(status().isBadRequest());
            assertPersistedStatus(appointment, initial);
        }
    }

    @Test void pendingAppointmentCannotBeCompletedWithoutConfirmation() throws Exception {
        var appointment = appointment(PENDING);
        update(appointment, hostAuth, COMPLETED).andExpect(status().isBadRequest());
        assertPersistedStatus(appointment, PENDING);
    }

    @Test void outsiderCannotConfirmCompleteOrCancelAndCannotSeeHistory() throws Exception {
        var appointment = appointment(CONFIRMED);
        for (var target : new ViewingAppointment.AppointmentStatus[]{CONFIRMED, COMPLETED,
                ViewingAppointment.AppointmentStatus.CANCELLED}) {
            update(appointment, outsiderAuth, target).andExpect(status().isForbidden());
            assertPersistedStatus(appointment, CONFIRMED);
        }
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", outsiderAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
    }

    @Test void anonymousOrLockedCallerCannotCreateListOrUpdateAppointment() throws Exception {
        var appointment = appointment(PENDING);
        long before = appointments.count();
        mvc.perform(post("/api/v1/appointments").contentType("application/json").content(createBody()))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/appointments/my")).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId()).param("status", "CONFIRMED"))
                .andExpect(status().isUnauthorized());
        requester.setStatus("LOCKED");
        users.saveAndFlush(requester);
        create(requesterAuth).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", requesterAuth))
                .andExpect(status().isUnauthorized());
        update(appointment, requesterAuth, ViewingAppointment.AppointmentStatus.CANCELLED)
                .andExpect(status().isUnauthorized());
        assertThat(appointments.count()).isEqualTo(before);
        assertPersistedStatus(appointment, PENDING);
    }

    @Test void revokedEligibilityDoesNotDeleteOrAutomaticallyChangeHistoricalAppointments() throws Exception {
        appointment(PENDING);
        appointment(CONFIRMED);
        room.setStatus(RoomPost.PostStatus.CLOSED);
        posts.saveAndFlush(room);
        block(true);
        for (String auth : new String[]{requesterAuth, hostAuth}) {
            mvc.perform(get("/api/v1/appointments/my").header("Authorization", auth))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
        }
        assertThat(appointments.findAllByUserId(requester.getId())).extracting(ViewingAppointment::getStatus)
                .containsExactlyInAnyOrder(PENDING, CONFIRMED);
    }

    private void assertHostOperationsDenied(int expectedStatus) throws Exception {
        var pending = appointment(PENDING);
        var confirmed = appointment(CONFIRMED);
        long before = appointments.count();
        update(pending, hostAuth, CONFIRMED).andExpect(status().is(expectedStatus));
        assertPersistedStatus(pending, PENDING);
        update(confirmed, hostAuth, CONFIRMED).andExpect(status().is(expectedStatus));
        assertPersistedStatus(confirmed, CONFIRMED);
        update(confirmed, hostAuth, COMPLETED).andExpect(status().is(expectedStatus));
        assertPersistedStatus(confirmed, CONFIRMED);
        assertThat(appointments.count()).isEqualTo(before);
    }

    private ResultActions create(String authorization) throws Exception {
        return mvc.perform(post("/api/v1/appointments").header("Authorization", authorization)
                .contentType("application/json").content(createBody()));
    }

    private String createBody() {
        return "{\"roomPostId\":" + room.getId() + ",\"appointmentTime\":\""
                + OffsetDateTime.now().plusDays(2).withNano(0) + "\",\"note\":\"Synthetic viewing note\"}";
    }

    private ResultActions update(ViewingAppointment appointment, String authorization,
                                 ViewingAppointment.AppointmentStatus target) throws Exception {
        return mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .header("Authorization", authorization).param("status", target.name()));
    }

    private void assertPersistedStatus(ViewingAppointment appointment, ViewingAppointment.AppointmentStatus expected) {
        appointments.flush();
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus()).isEqualTo(expected);
    }

    private User user(String name) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
    }

    private String token(User user) {
        var grant = grants.saveAndFlush(RefreshToken.builder().user(user).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private ViewingAppointment appointment(ViewingAppointment.AppointmentStatus initial) {
        return appointments.saveAndFlush(ViewingAppointment.builder().requester(requester).host(host).roomPost(room)
                .appointmentTime(OffsetDateTime.now().plusDays(2)).status(initial).note("Synthetic viewing note").build());
    }

    private void acceptedConnection() {
        matches.saveAndFlush(MatchRequest.builder().sender(requester).receiver(host)
                .matchScore(80.0).status(MatchRequest.MatchStatus.ACCEPTED).build());
    }

    private void block(boolean hostBlocks) {
        blocks.saveAndFlush(BlockedUser.builder().user(hostBlocks ? host : requester)
                .blockedUser(hostBlocks ? requester : host).build());
    }
}
