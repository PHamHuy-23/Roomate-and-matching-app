package com.roommate.hub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateReportDTO {

    @NotNull(message = "ID đối tượng báo cáo không được để trống")
    private Long targetId;

    private String targetType;

    @NotBlank(message = "Lý do báo cáo không được để trống")
    private String reason;
    private String evidenceObjectKey;
}
