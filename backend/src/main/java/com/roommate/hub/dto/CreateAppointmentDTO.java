package com.roommate.hub.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateAppointmentDTO {

    @NotNull(message = "ID bài đăng phòng không được để trống")
    private Long roomPostId;

    @NotNull(message = "Thời gian xem phòng không được để trống")
    @Future(message = "Thời gian xem phòng phải ở trong tương lai")
    private OffsetDateTime appointmentTime;

    private String note;
}
