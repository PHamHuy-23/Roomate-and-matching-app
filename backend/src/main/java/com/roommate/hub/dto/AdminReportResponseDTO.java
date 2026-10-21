package com.roommate.hub.dto;

import com.roommate.hub.entity.Report;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminReportResponseDTO {
    private Long id;
    private Long reporterId;
    private String reporterName;
    private String reporterEmail;
    private Long targetId;
    private String targetType;
    private String reason;
    private String status;
    private String actionNote;
    private String evidenceUrl;
    private LocalDateTime createdAt;

    public static AdminReportResponseDTO from(Report report) {
        return AdminReportResponseDTO.builder()
                .id(report.getId())
                .reporterId(report.getReporter() != null ? report.getReporter().getId() : null)
                .reporterName(report.getReporter() != null ? report.getReporter().getFullName() : "Ẩn danh")
                .reporterEmail(report.getReporter() != null ? report.getReporter().getEmail() : "")
                .targetId(report.getTargetId())
                .targetType(report.getTargetType())
                .reason(report.getReason())
                .status(report.getStatus())
                .actionNote(report.getActionNote())
                // Never expose a stored key or legacy public evidence URL from the generic mapper.
                .evidenceUrl(null)
                .createdAt(report.getCreatedAt())
                .build();
    }
}
