package com.roommate.hub.repository;

import com.roommate.hub.entity.ViewingAppointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;

import java.util.List;
import java.util.Optional;

@Repository
public interface ViewingAppointmentRepository extends JpaRepository<ViewingAppointment, Long> {
    // An idempotent confirmation must also validate that its read version is current.
    @Lock(LockModeType.OPTIMISTIC)
    @Query("SELECT a FROM ViewingAppointment a WHERE a.id = :id")
    Optional<ViewingAppointment> findByIdForStatusUpdate(@Param("id") Long id);

    @Query("SELECT a FROM ViewingAppointment a WHERE ((a.requester.id = :u1 AND a.host.id = :u2) OR (a.requester.id = :u2 AND a.host.id = :u1)) AND a.status IN ('PENDING', 'CONFIRMED') AND a.appointmentTime > :now")
    List<ViewingAppointment> findActiveUpcomingBetweenUsers(@Param("u1") Long u1, @Param("u2") Long u2, @Param("now") java.time.OffsetDateTime now);

    @Query("SELECT a FROM ViewingAppointment a WHERE a.requester.id = :userId OR a.host.id = :userId ORDER BY a.appointmentTime DESC")
    List<ViewingAppointment> findAllByUserId(@Param("userId") Long userId);

    List<ViewingAppointment> findByRequesterIdOrderByAppointmentTimeDesc(Long requesterId);

    List<ViewingAppointment> findByHostIdOrderByAppointmentTimeDesc(Long hostId);

    List<ViewingAppointment> findByRoomPostId(Long roomPostId);

    List<ViewingAppointment> findByStatusAndReminderSentFalseAndAppointmentTimeBetween(
        ViewingAppointment.AppointmentStatus status,
        java.time.Instant start,
        java.time.Instant end
    );

    List<ViewingAppointment> findByStatusAndReminderSentFalseAndAppointmentTimeBetween(
        ViewingAppointment.AppointmentStatus status,
        java.time.OffsetDateTime start,
        java.time.OffsetDateTime end
    );
}
