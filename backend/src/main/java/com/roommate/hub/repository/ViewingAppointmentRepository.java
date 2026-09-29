package com.roommate.hub.repository;

import com.roommate.hub.entity.ViewingAppointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ViewingAppointmentRepository extends JpaRepository<ViewingAppointment, Long> {

    @Query("SELECT a FROM ViewingAppointment a WHERE a.requester.id = :userId OR a.host.id = :userId ORDER BY a.appointmentTime DESC")
    List<ViewingAppointment> findAllByUserId(@Param("userId") Long userId);

    List<ViewingAppointment> findByRequesterIdOrderByAppointmentTimeDesc(Long requesterId);

    List<ViewingAppointment> findByHostIdOrderByAppointmentTimeDesc(Long hostId);

    List<ViewingAppointment> findByRoomPostId(Long roomPostId);
}
