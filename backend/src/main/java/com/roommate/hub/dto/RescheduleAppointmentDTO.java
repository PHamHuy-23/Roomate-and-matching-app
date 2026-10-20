package com.roommate.hub.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RescheduleAppointmentDTO {
    @NotNull(message = "Thời gian đề xuất mới không được để trống")
    @Future(message = "Thời gian đề xuất mới phải ở tương lai")
    private Instant newAppointmentTime;

    private String note;
}
