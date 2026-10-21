package com.roommate.hub.service;

import com.roommate.hub.dto.AuditLogResponseDTO;
import com.roommate.hub.entity.AuditLog;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.AuditLogRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final UserRepository userRepository;

    @Transactional
    public AuditLog logAction(String action, String targetType, Long targetId, String details) {
        Long actorId = null;
        String actorEmail = null;

        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && auth.getName() != null && !"anonymousUser".equals(auth.getName())) {
                actorEmail = auth.getName();
                actorId = userRepository.findByEmail(actorEmail).map(User::getId).orElse(null);
            }
        } catch (Exception e) {
            log.warn("Could not determine current authenticated user for audit log: {}", e.getMessage());
        }

        return logAction(actorId, actorEmail, action, targetType, targetId, details);
    }

    @Transactional
    public AuditLog logAction(Long actorId, String actorEmail, String action, String targetType, Long targetId, String details) {
        AuditLog auditLog = AuditLog.builder()
                .actorId(actorId)
                .actorEmail(actorEmail)
                .action(action)
                .targetType(targetType)
                .targetId(targetId)
                .details(details)
                .createdAt(Instant.now())
                .build();
        return auditLogRepository.save(auditLog);
    }

    @Transactional(readOnly = true)
    public List<AuditLogResponseDTO> getAuditLogs() {
        return auditLogRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(AuditLogResponseDTO::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AuditLogResponseDTO> getAuditLogs(Pageable pageable) {
        return auditLogRepository.findAllByOrderByCreatedAtDesc(pageable)
                .map(AuditLogResponseDTO::from)
                .getContent();
    }
}
