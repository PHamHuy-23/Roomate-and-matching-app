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
import com.roommate.hub.service.MatchRequestService;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class AppointmentContactPrivacyIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired MatchRequestRepository requests;
    @Autowired BlockedUserRepository blocks;
    @Autowired RefreshTokenRepository grants;
    @Autowired MatchRequestService matches;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;

    private MockMvc mvc;
    private User requester, host, outsider;
    private String requesterAuth, hostAuth, outsiderAuth;
    private RoomPost room;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        requester = user("Requester", "0000000001");
        host = user("Host", "0000000002");
        outsider = user("Outsider", "0000000003");
        requesterAuth = token(requester);
        hostAuth = token(host);
        outsiderAuth = token(outsider);
        room = posts.saveAndFlush(RoomPost.builder().author(host).title("Privacy test room")
                .description("Synthetic test room").address("Synthetic test address").price(2500000.0)
                .maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
    }

    @AfterEach void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test void creationHidesBothPhonesWithoutDoubleOptInButKeepsAppointmentData() throws Exception {
        assertRedacted(create(), "$")
                .andExpect(jsonPath("requesterId").value(requester.getId()))
                .andExpect(jsonPath("hostId").value(host.getId()))
                .andExpect(jsonPath("status").value("PENDING"))
                .andExpect(jsonPath("roomTitle").value(room.getTitle()))
                .andExpect(jsonPath("note").value("Synthetic viewing note"));
        assertThat(appointments.findAllByUserId(requester.getId())).hasSize(1);
    }

    @ParameterizedTest
    @EnumSource(ViewingAppointment.AppointmentStatus.class)
    void listingHidesBothPhonesForBothParticipantsInEveryAppointmentState(
            ViewingAppointment.AppointmentStatus appointmentStatus) throws Exception {
        var appointment = appointment(appointmentStatus);
        for (String auth : new String[]{requesterAuth, hostAuth}) {
            assertRedacted(list(auth).andExpect(jsonPath("$", hasSize(1))), "$[0]")
                    .andExpect(jsonPath("$[0].id").value(appointment.getId()))
                    .andExpect(jsonPath("$[0].status").value(appointmentStatus.name()));
        }
    }

    @Test void statusChangesAndSameStatusEarlyReturnDoNotGrantContact() throws Exception {
        var appointment = appointment(ViewingAppointment.AppointmentStatus.PENDING);
        assertRedacted(update(appointment, requesterAuth, "PENDING"), "$");
        assertRedacted(update(appointment, hostAuth, "CONFIRMED"), "$")
                .andExpect(jsonPath("status").value("CONFIRMED"));
        assertRedacted(update(appointment, hostAuth, "CONFIRMED"), "$");
        assertRedacted(update(appointment, hostAuth, "COMPLETED"), "$")
                .andExpect(jsonPath("status").value("COMPLETED"));

        var cancellable = appointment(ViewingAppointment.AppointmentStatus.CONFIRMED);
        assertRedacted(update(cancellable, requesterAuth, "CANCELLED"), "$")
                .andExpect(jsonPath("status").value("CANCELLED"));
    }

    @ParameterizedTest
    @EnumSource(value = MatchRequest.MatchStatus.class, names = {"PENDING", "REJECTED"})
    void unacceptedMatchesNeverUnlockContact(MatchRequest.MatchStatus matchStatus) throws Exception {
        match(requester, host, matchStatus);
        assertRedacted(create(), "$");
        assertRedacted(list(requesterAuth), "$[0]");
        assertRedacted(list(hostAuth), "$[0]");
    }

    @Test void anAcceptedMatchWithAnotherUserDoesNotUnlockThisAppointmentsContact() throws Exception {
        match(requester, outsider, MatchRequest.MatchStatus.ACCEPTED);
        match(outsider, host, MatchRequest.MatchStatus.ACCEPTED);
        assertRedacted(create(), "$");
        assertRedacted(list(requesterAuth), "$[0]");
        assertRedacted(list(hostAuth), "$[0]");
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void acceptedMatchInEitherDirectionUnlocksBothPhonesIndependentlyOfAppointmentStatus(
            boolean hostSendsMatch) throws Exception {
        match(hostSendsMatch ? host : requester, hostSendsMatch ? requester : host,
                MatchRequest.MatchStatus.ACCEPTED);
        assertGranted(create(), "$");
        var pending = appointments.findAllByUserId(requester.getId()).getFirst();
        assertGranted(update(pending, requesterAuth, "PENDING"), "$");
        assertGranted(update(pending, hostAuth, "CONFIRMED"), "$");
        assertGranted(update(pending, hostAuth, "CONFIRMED"), "$");
        assertGranted(update(pending, hostAuth, "COMPLETED"), "$");
        appointment(ViewingAppointment.AppointmentStatus.PENDING);
        appointment(ViewingAppointment.AppointmentStatus.CONFIRMED);
        appointment(ViewingAppointment.AppointmentStatus.CANCELLED);

        // A cancelled viewing is not a cancelled, independently accepted roommate connection.
        for (String auth : new String[]{requesterAuth, hostAuth}) {
            var response = list(auth).andExpect(jsonPath("$", hasSize(4)));
            for (int i = 0; i < 4; i++) assertGranted(response, "$[" + i + "]");
        }
    }

    @Test void cancellingConnectionRevokesContactForExistingConfirmedAppointmentImmediately() throws Exception {
        match(requester, host, MatchRequest.MatchStatus.ACCEPTED);
        match(host, requester, MatchRequest.MatchStatus.PENDING);
        var appointment = appointment(ViewingAppointment.AppointmentStatus.CONFIRMED);
        assertGranted(list(requesterAuth), "$[0]");
        assertGranted(list(hostAuth), "$[0]");

        matches.cancelConnection(requester.getId(), host.getId());
        requests.flush();
        assertThat(requests.findAllBetweenUsers(requester.getId(), host.getId())).isEmpty();
        assertRedacted(list(requesterAuth), "$[0]");
        assertRedacted(list(hostAuth), "$[0]");
        assertRedacted(update(appointment, hostAuth, "CONFIRMED"), "$");
        assertRedacted(update(appointment, hostAuth, "COMPLETED"), "$");
        assertThat(appointments.findById(appointment.getId())).isPresent();
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void blockingInEitherDirectionRevokesAcceptedContactWithoutRemovingAppointmentHistory(
            boolean hostBlocksRequester) throws Exception {
        match(requester, host, MatchRequest.MatchStatus.ACCEPTED);
        var appointment = appointment(ViewingAppointment.AppointmentStatus.CONFIRMED);
        assertGranted(list(requesterAuth), "$[0]");
        blocks.saveAndFlush(BlockedUser.builder()
                .user(hostBlocksRequester ? host : requester)
                .blockedUser(hostBlocksRequester ? requester : host).build());

        assertRedacted(list(requesterAuth).andExpect(jsonPath("$", hasSize(1))), "$[0]");
        assertRedacted(list(hostAuth).andExpect(jsonPath("$", hasSize(1))), "$[0]");
        mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .header("Authorization", hostAuth).param("status", "CONFIRMED"))
                .andExpect(status().isForbidden());
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CONFIRMED);
        assertRedacted(update(appointment, requesterAuth, "CANCELLED"), "$");
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void lockedCounterpartRevokesContactForActiveParticipant(boolean lockHost) throws Exception {
        match(requester, host, MatchRequest.MatchStatus.ACCEPTED);
        var appointment = appointment(ViewingAppointment.AppointmentStatus.CONFIRMED);
        var lockedUser = lockHost ? host : requester;
        lockedUser.setStatus("LOCKED");
        users.saveAndFlush(lockedUser);

        assertRedacted(list(lockHost ? requesterAuth : hostAuth)
                .andExpect(jsonPath("$", hasSize(1))), "$[0]");
        mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .header("Authorization", lockHost ? requesterAuth : hostAuth).param("status", "CONFIRMED"))
                .andExpect(status().isForbidden());
        assertRedacted(update(appointment, lockHost ? requesterAuth : hostAuth, "CANCELLED"), "$");
        mvc.perform(get("/api/v1/appointments/my")
                .header("Authorization", lockHost ? hostAuth : requesterAuth))
                .andExpect(status().isUnauthorized());
    }

    @Test void outsidersAndAnonymousCallersCannotObtainAnotherPairsContact() throws Exception {
        match(requester, host, MatchRequest.MatchStatus.ACCEPTED);
        var appointment = appointment(ViewingAppointment.AppointmentStatus.PENDING);
        list(outsiderAuth).andExpect(jsonPath("$", hasSize(0)));
        mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .header("Authorization", outsiderAuth).param("status", "CONFIRMED"))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/appointments/my")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/appointments").contentType("application/json")
                .content(createBody())).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .param("status", "PENDING")).andExpect(status().isUnauthorized());
    }

    private ResultActions create() throws Exception {
        return mvc.perform(post("/api/v1/appointments").header("Authorization", requesterAuth)
                .contentType("application/json").content(createBody())).andExpect(status().isOk());
    }

    private String createBody() {
        return "{\"roomPostId\":" + room.getId() + ",\"appointmentTime\":\""
                + OffsetDateTime.now().plusDays(2).withNano(0)
                + "\",\"note\":\"Synthetic viewing note\"}";
    }

    private ResultActions list(String authorization) throws Exception {
        return mvc.perform(get("/api/v1/appointments/my").header("Authorization", authorization))
                .andExpect(status().isOk());
    }

    private ResultActions update(ViewingAppointment appointment, String authorization, String target) throws Exception {
        return mvc.perform(put("/api/v1/appointments/{id}/status", appointment.getId())
                .header("Authorization", authorization).param("status", target)).andExpect(status().isOk());
    }

    private ResultActions assertRedacted(ResultActions response, String path) throws Exception {
        response.andExpect(jsonPath(path + ".requesterPhone").doesNotExist())
                .andExpect(jsonPath(path + ".hostPhone").doesNotExist());
        assertThat(response.andReturn().getResponse().getContentAsString())
                .doesNotContain(requester.getPhone(), host.getPhone());
        return response;
    }

    private ResultActions assertGranted(ResultActions response, String path) throws Exception {
        return response.andExpect(jsonPath(path + ".requesterPhone").value(requester.getPhone()))
                .andExpect(jsonPath(path + ".hostPhone").value(host.getPhone()));
    }

    private User user(String name, String phone) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE").phone(phone)
                .role(User.Role.ROLE_USER).build());
    }

    private String token(User user) {
        var grant = grants.saveAndFlush(RefreshToken.builder().user(user).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private void match(User sender, User receiver, MatchRequest.MatchStatus matchStatus) {
        requests.saveAndFlush(MatchRequest.builder().sender(sender).receiver(receiver)
                .matchScore(80.0).status(matchStatus).build());
    }

    private ViewingAppointment appointment(ViewingAppointment.AppointmentStatus appointmentStatus) {
        return appointments.saveAndFlush(ViewingAppointment.builder().requester(requester).host(host).roomPost(room)
                .appointmentTime(OffsetDateTime.now().plusDays(2)).status(appointmentStatus)
                .note("Synthetic viewing note").build());
    }
}
