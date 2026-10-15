package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class RequesterAppointmentIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    MockMvc mvc;
    User requester, host, stranger;
    String requesterAuth, hostAuth, strangerAuth;
    RoomPost room;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        requester = user("Requester"); host = user("Host"); stranger = user("Stranger");
        requesterAuth = token(requester); hostAuth = token(host); strangerAuth = token(stranger);
        room = posts.saveAndFlush(RoomPost.builder().author(host).title("Actual room title")
                .description("Actual description").address("Actual address").price(2500000.0)
                .maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
    }
    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void creationReturnsActualTimeAndAuthenticatedParticipants() throws Exception {
        OffsetDateTime time = OffsetDateTime.now().plusDays(2).withNano(0);
        mvc.perform(post("/api/v1/appointments").header("Authorization", requesterAuth)
                .contentType("application/json").content("{\"roomPostId\":" + room.getId()
                        + ",\"appointmentTime\":\"" + time + "\",\"note\":\"Actual note\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("requesterId").value(requester.getId()))
                .andExpect(jsonPath("hostId").value(host.getId())).andExpect(jsonPath("status").value("PENDING"))
                .andExpect(jsonPath("roomTitle").value("Actual room title")).andExpect(jsonPath("note").value("Actual note"));
        var saved = appointments.findAllByUserId(requester.getId());
        assertThat(saved).hasSize(1);
        assertThat(saved.getFirst().getAppointmentTime().toInstant()).isEqualTo(time.toInstant());
    }

    @Test void myAppointmentsContainsOnlyAuthenticatedUsersIncomingAndOutgoingAppointments() throws Exception {
        var outgoing = appointment(requester, host, ViewingAppointment.AppointmentStatus.PENDING);
        var incoming = appointment(stranger, requester, ViewingAppointment.AppointmentStatus.CONFIRMED);
        appointment(stranger, host, ViewingAppointment.AppointmentStatus.PENDING);
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", requesterAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[*].id", org.hamcrest.Matchers.containsInAnyOrder(
                        outgoing.getId().intValue(), incoming.getId().intValue())));
    }

    @Test void requesterCanCancelPendingAndConfirmedAppointmentsAndReloadTheirStatus() throws Exception {
        for (var initial : new ViewingAppointment.AppointmentStatus[]{
                ViewingAppointment.AppointmentStatus.PENDING, ViewingAppointment.AppointmentStatus.CONFIRMED}) {
            var apt = appointment(requester, host, initial);
            mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                    .header("Authorization", requesterAuth).param("status", "CANCELLED"))
                    .andExpect(status().isOk()).andExpect(jsonPath("id").value(apt.getId()))
                    .andExpect(jsonPath("status").value("CANCELLED"));
            appointments.flush();
            assertThat(appointments.findById(apt.getId()).orElseThrow().getStatus())
                    .isEqualTo(ViewingAppointment.AppointmentStatus.CANCELLED);
        }
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", requesterAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$[*].status",
                        org.hamcrest.Matchers.everyItem(org.hamcrest.Matchers.is("CANCELLED"))));
    }

    @Test void requesterCannotConfirmOrCompleteAppointments() throws Exception {
        var apt = appointment(requester, host, ViewingAppointment.AppointmentStatus.PENDING);
        mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                .header("Authorization", requesterAuth).param("status", "CONFIRMED"))
                .andExpect(status().isForbidden());
        assertThat(apt.getStatus()).isEqualTo(ViewingAppointment.AppointmentStatus.PENDING);
        apt.setStatus(ViewingAppointment.AppointmentStatus.CONFIRMED);
        mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                .header("Authorization", requesterAuth).param("status", "COMPLETED"))
                .andExpect(status().isForbidden());
        assertThat(apt.getStatus()).isEqualTo(ViewingAppointment.AppointmentStatus.CONFIRMED);
    }

    @Test void outsidersCannotCancelAndTerminalStatesCannotBeCancelledAgain() throws Exception {
        var apt = appointment(requester, host, ViewingAppointment.AppointmentStatus.PENDING);
        mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                .header("Authorization", strangerAuth).param("status", "CANCELLED"))
                .andExpect(status().isForbidden());
        assertThat(apt.getStatus()).isEqualTo(ViewingAppointment.AppointmentStatus.PENDING);
        for (var terminal : new ViewingAppointment.AppointmentStatus[]{
                ViewingAppointment.AppointmentStatus.CANCELLED, ViewingAppointment.AppointmentStatus.COMPLETED}) {
            apt.setStatus(terminal);
            mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                    .header("Authorization", requesterAuth).param("status", "CANCELLED"))
                    .andExpect(status().isBadRequest());
            assertThat(apt.getStatus()).isEqualTo(terminal);
        }
    }

    @Test void hostConfirmationRemainsVisibleToRequester() throws Exception {
        var apt = appointment(requester, host, ViewingAppointment.AppointmentStatus.PENDING);
        mvc.perform(put("/api/v1/appointments/{id}/status", apt.getId())
                .header("Authorization", hostAuth).param("status", "CONFIRMED"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/appointments/my").header("Authorization", requesterAuth))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].status").value("CONFIRMED"));
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
    private ViewingAppointment appointment(User requester, User host, ViewingAppointment.AppointmentStatus status) {
        RoomPost appointmentRoom = room;
        if (!room.getAuthor().getId().equals(host.getId())) {
            appointmentRoom = posts.saveAndFlush(RoomPost.builder().author(host).title("Incoming room")
                    .description("Actual description").address("Actual address").price(2500000.0)
                    .maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
        }
        return appointments.saveAndFlush(ViewingAppointment.builder().requester(requester).host(host).roomPost(appointmentRoom)
                .appointmentTime(OffsetDateTime.now().plusDays(2)).status(status).note("Actual note").build());
    }
}
