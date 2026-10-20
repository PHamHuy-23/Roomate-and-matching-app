package com.roommate.hub.dto;

import com.roommate.hub.entity.AuditLog;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogResponseDTO {
    private Long id;
    private Long actorId;
    private String actorEmail;
    private String action;
    private String targetType;
    private Long targetId;
    private String details;
    private Instant createdAt;

    public static AuditLogResponseDTO from(AuditLog log) {
        if (log == null) {
            return null;
        }
        return AuditLogResponseDTO.builder()
                .id(log.getId())
                .actorId(log.getActorId())
                .actorEmail(log.getActorEmail())
                .action(log.getAction())
                .targetType(log.getTargetType())
                .targetId(log.getTargetId())
                .details(log.getDetails())
                .createdAt(log.getCreatedAt())
                .build();
    }
}
