package com.roommate.hub.dto;

import com.roommate.hub.entity.ViewingAppointment;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppointmentResponseDTO {
    private Long id;
    private Long requesterId;
    private String requesterName;
    private String requesterPhone;
    private String requesterAvatar;

    private Long hostId;
    private String hostName;
    private String hostPhone;
    private String hostAvatar;

    private Long roomPostId;
    private String roomTitle;
    private String roomAddress;
    private Double roomPrice;

    private java.time.OffsetDateTime appointmentTime;
    private String status;
    private String note;
    private LocalDateTime createdAt;

    public static AppointmentResponseDTO from(ViewingAppointment appointment) {
        return AppointmentResponseDTO.builder()
                .id(appointment.getId())
                .requesterId(appointment.getRequester().getId())
                .requesterName(appointment.getRequester().getFullName())
                .requesterPhone(appointment.getRequester().getPhone())
                .requesterAvatar(appointment.getRequester().getAvatarUrl())
                .hostId(appointment.getHost().getId())
                .hostName(appointment.getHost().getFullName())
                .hostPhone(appointment.getHost().getPhone())
                .hostAvatar(appointment.getHost().getAvatarUrl())
                .roomPostId(appointment.getRoomPost().getId())
                .roomTitle(appointment.getRoomPost().getTitle())
                .roomAddress(appointment.getRoomPost().getAddress())
                .roomPrice(appointment.getRoomPost().getPrice())
                .appointmentTime(appointment.getAppointmentTime())
                .status(appointment.getStatus().name())
                .note(appointment.getNote())
                .createdAt(appointment.getCreatedAt())
                .build();
    }
}
