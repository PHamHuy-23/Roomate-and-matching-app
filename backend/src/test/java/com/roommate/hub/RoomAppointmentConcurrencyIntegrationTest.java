package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import com.roommate.hub.service.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.*;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Independent committed H2 transactions, deliberately held by latches (not sleeps).
// Never uses Supabase, R2, real accounts or real data.
@SpringBootTest
class RoomAppointmentConcurrencyIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired ViewingAppointmentRepository appointments;
    @Autowired RefreshTokenRepository grants;
    @Autowired AppointmentService appointmentService;
    @Autowired RoomPostService roomService;
    @Autowired AdminService adminService;
    @Autowired EntityManager em;
    @Autowired PlatformTransactionManager transactionManager;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    @Autowired JwtUtils jwt;

    private User host, requester, admin;
    private RoomPost room;
    private ViewingAppointment appointment;
    private String adminAuth;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        host = user("Host", User.Role.ROLE_USER);
        requester = user("Requester", User.Role.ROLE_USER);
        admin = user("Admin", User.Role.ROLE_ADMIN);
        room = posts.saveAndFlush(RoomPost.builder().author(host).title("Original reviewed content")
                .description("Original description").price(2_000_000.0).address("Synthetic address")
                .maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
        appointment = appointments.saveAndFlush(ViewingAppointment.builder().requester(requester).host(host)
                .roomPost(room).appointmentTime(OffsetDateTime.now().plusDays(1)).build());
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(admin).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
        adminAuth = "Bearer " + jwt.generateToken(admin.getEmail(), admin.getId(), grant.getId());
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }

    @AfterEach void tearDown() {
        SecurityContextHolder.clearContext();
        // Only records created by this test; preserve fixtures belonging to other tests.
        new TransactionTemplate(transactionManager).executeWithoutResult(tx -> {
            appointments.deleteById(appointment.getId());
            posts.deleteById(room.getId());
            grants.deleteAll(grants.findAll().stream().filter(g -> g.getUser().getId().equals(admin.getId())).toList());
            users.deleteAllById(List.of(host.getId(), requester.getId(), admin.getId()));
        });
    }

    @Test void staleConfirmationCannotOverwriteCommittedCancellation() throws Exception {
        staleWrite(ViewingAppointment.class, appointment.getId(), host,
                () -> appointmentService.updateStatus(appointment.getId(), "CONFIRMED"),
                () -> as(requester, () -> appointmentService.updateStatus(appointment.getId(), "CANCELLED")));
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CANCELLED);
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getVersion()).isEqualTo(1L);
    }

    @Test void staleCancellationCannotOverwriteConfirmationAndCanBeRetriedFromNewState() throws Exception {
        staleWrite(ViewingAppointment.class, appointment.getId(), requester,
                () -> appointmentService.updateStatus(appointment.getId(), "CANCELLED"),
                () -> as(host, () -> appointmentService.updateStatus(appointment.getId(), "CONFIRMED")));
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CONFIRMED);
        as(requester, () -> appointmentService.updateStatus(appointment.getId(), "CANCELLED"));
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CANCELLED);
    }

    @Test void staleCompletionCannotRestoreCancelledAppointment() throws Exception {
        as(host, () -> appointmentService.updateStatus(appointment.getId(), "CONFIRMED"));
        staleWrite(ViewingAppointment.class, appointment.getId(), host,
                () -> appointmentService.updateStatus(appointment.getId(), "COMPLETED"),
                () -> as(requester, () -> appointmentService.updateStatus(appointment.getId(), "CANCELLED")));
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CANCELLED);
    }

    @Test void repeatedConfirmationWithoutDirtyFieldsStillRejectsConcurrentCancellation() throws Exception {
        as(host, () -> appointmentService.updateStatus(appointment.getId(), "CONFIRMED"));
        staleWrite(ViewingAppointment.class, appointment.getId(), host,
                () -> appointmentService.updateStatus(appointment.getId(), "CONFIRMED"),
                () -> as(requester, () -> appointmentService.updateStatus(appointment.getId(), "CANCELLED")));
        assertThat(appointments.findById(appointment.getId()).orElseThrow().getStatus())
                .isEqualTo(ViewingAppointment.AppointmentStatus.CANCELLED);
    }

    @Test void unchangedApprovalWithoutReasonStillRejectsConcurrentUnreviewedEdit() throws Exception {
        staleWrite(RoomPost.class, room.getId(), admin,
                () -> adminService.moderatePost(room.getId(), "APPROVED", null, room.getVersion()),
                () -> as(host, () -> roomService.updatePost(room.getId(), edit("New unreviewed content"))));
        RoomPost persisted = posts.findById(room.getId()).orElseThrow();
        assertThat(persisted.getTitle()).isEqualTo("New unreviewed content");
        assertThat(persisted.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
    }

    @Test void editCommittedAfterModerationReadCannotBeApprovedOrOverwritten() throws Exception {
        staleWrite(RoomPost.class, room.getId(), admin,
                () -> adminService.moderatePost(room.getId(), "APPROVED", "Old review", room.getVersion()),
                () -> as(host, () -> roomService.updatePost(room.getId(), edit("New unreviewed content"))));
        RoomPost persisted = posts.findById(room.getId()).orElseThrow();
        assertThat(persisted.getTitle()).isEqualTo("New unreviewed content");
        assertThat(persisted.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
        assertThat(persisted.getModerationReason()).isNull();
    }

    @Test void staleOwnerEditCannotOverwriteNewModerationDecision() throws Exception {
        staleWrite(RoomPost.class, room.getId(), host,
                () -> roomService.updatePost(room.getId(), edit("Stale edit")),
                () -> as(admin, () -> adminService.moderatePost(room.getId(), "REJECTED", "Reviewed rejection", room.getVersion())));
        RoomPost persisted = posts.findById(room.getId()).orElseThrow();
        assertThat(persisted.getTitle()).isEqualTo("Original reviewed content");
        assertThat(persisted.getStatus()).isEqualTo(RoomPost.PostStatus.REJECTED);
        assertThat(persisted.getModerationReason()).isEqualTo("Reviewed rejection");
    }

    @Test void closingRoomAfterModerationReadCannotBeUndoneByStaleApproval() throws Exception {
        staleWrite(RoomPost.class, room.getId(), admin,
                () -> adminService.moderatePost(room.getId(), "APPROVED", "Old review", room.getVersion()),
                () -> as(host, () -> roomService.deletePost(room.getId())));
        assertThat(posts.findById(room.getId()).orElseThrow().getStatus()).isEqualTo(RoomPost.PostStatus.CLOSED);
    }

    @ParameterizedTest @ValueSource(strings = {"APPROVED", "REJECTED", "CLOSED"})
    void httpRejectsReviewOfOldSnapshotAndAllowsExplicitReviewOfLatest(String decision) throws Exception {
        long viewedVersion = room.getVersion();
        mvc.perform(get("/api/v1/admin/posts").header("Authorization", adminAuth))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", containsString("no-store")))
                .andExpect(jsonPath("$[?(@.id == " + room.getId() + ")].version").value(org.hamcrest.Matchers.hasItem(0)));
        as(host, () -> roomService.updatePost(room.getId(), edit("Changed after admin viewed")));
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", room.getId()).header("Authorization", adminAuth)
                        .param("status", decision).param("reason", "Stale reason").param("expectedVersion", "" + viewedVersion))
                .andExpect(status().isConflict()).andExpect(jsonPath("status").value(409));
        RoomPost latest = posts.findById(room.getId()).orElseThrow();
        assertThat(latest.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
        assertThat(latest.getModerationReason()).isNull();
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", room.getId()).header("Authorization", adminAuth)
                        .param("status", decision).param("reason", "New review").param("expectedVersion", "" + latest.getVersion()))
                .andExpect(status().isOk()).andExpect(jsonPath("status").value(decision))
                .andExpect(jsonPath("version").value(latest.getVersion() + 1));
    }

    @Test void sameSnapshotCannotOverwriteAnotherAdminsDecision() throws Exception {
        long viewedVersion = room.getVersion();
        as(admin, () -> adminService.moderatePost(room.getId(), "REJECTED", "First review", viewedVersion));
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", room.getId()).header("Authorization", adminAuth)
                        .param("status", "APPROVED").param("expectedVersion", "" + viewedVersion))
                .andExpect(status().isConflict());
        assertThat(posts.findById(room.getId()).orElseThrow().getModerationReason()).isEqualTo("First review");
    }

    @Test void noVersionBypassAndMalformedVersionsAreBadRequests() throws Exception {
        mvc.perform(put("/api/v1/admin/posts/{id}/moderate", room.getId()).header("Authorization", adminAuth)
                        .param("status", "REJECTED"))
                .andExpect(status().isBadRequest());
        for (String value : List.of("-1", "not-a-number", "9223372036854775808")) {
            mvc.perform(put("/api/v1/admin/posts/{id}/moderate", room.getId()).header("Authorization", adminAuth)
                            .param("status", "REJECTED").param("expectedVersion", value))
                    .andExpect(status().isBadRequest());
        }
        assertThat(posts.findById(room.getId()).orElseThrow().getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
        assertThat(posts.findById(room.getId()).orElseThrow().getVersion()).isZero();
    }

    private <T> void staleWrite(Class<T> entityType, Long id, User actor,
                                Runnable staleAction, Runnable winningAction) throws Exception {
        var loaded = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        var executor = Executors.newSingleThreadExecutor();
        Future<Throwable> stale = executor.submit(() -> {
            try {
                new TransactionTemplate(transactionManager).executeWithoutResult(tx -> as(actor, () -> {
                    assertThat(em.find(entityType, id)).isNotNull(); // retained old version in this persistence context
                    loaded.countDown();
                    await(release);
                    staleAction.run();
                }));
                return null;
            } catch (Throwable error) {
                return error;
            } finally {
                SecurityContextHolder.clearContext();
            }
        });
        try {
            assertThat(loaded.await(10, TimeUnit.SECONDS)).isTrue();
            winningAction.run(); // separate committed transaction while the stale transaction is paused
            release.countDown();
            assertThat(stale.get(10, TimeUnit.SECONDS)).isInstanceOf(OptimisticLockingFailureException.class);
        } finally {
            release.countDown();
            executor.shutdownNow();
            assertThat(executor.awaitTermination(10, TimeUnit.SECONDS)).isTrue();
        }
    }

    private static void await(CountDownLatch latch) {
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) throw new AssertionError("Timed out waiting for competing transaction");
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new AssertionError(ex);
        }
    }

    private static void as(User actor, Runnable action) {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                actor.getEmail(), null, List.of(new SimpleGrantedAuthority(actor.getRole().name()))));
        try { action.run(); } finally { SecurityContextHolder.clearContext(); }
    }

    private CreateRoomPostDTO edit(String title) {
        CreateRoomPostDTO dto = new CreateRoomPostDTO();
        dto.setTitle(title);
        return dto;
    }

    private User user(String name, User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .passwordHash("test-only-placeholder").fullName(name).gender("MALE").role(role).build());
    }
}
