package com.roommate.hub.service;

import com.roommate.hub.dto.CreateReportDTO;
import com.roommate.hub.entity.Report;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final com.roommate.hub.repository.RoomPostRepository roomPostRepository;
    private final org.springframework.beans.factory.ObjectProvider<R2StorageService> storageServiceProvider;

    @Transactional
    public Map<String, Object> createReport(CreateReportDTO dto) {
        User reporter = currentUser();
        String targetType = dto.getTargetType() == null ? "USER" : dto.getTargetType().trim().toUpperCase(java.util.Locale.ROOT);
        if (dto.getTargetId() == null || dto.getTargetId() <= 0) {
            throw new IllegalArgumentException("Đối tượng báo cáo không hợp lệ");
        }
        if ("USER".equals(targetType)) {
            if (reporter.getId().equals(dto.getTargetId())) throw new IllegalArgumentException("Không thể tự báo cáo");
            if (!userRepository.existsById(dto.getTargetId())) throw new ResourceNotFoundException("Người dùng không tồn tại");
        } else if ("ROOM_POST".equals(targetType)) {
            if (!roomPostRepository.existsById(dto.getTargetId())) throw new ResourceNotFoundException("Tin đăng không tồn tại");
        } else {
            throw new IllegalArgumentException("Loại đối tượng báo cáo không hợp lệ");
        }

        String evidenceUrl = null;
        if (dto.getEvidenceObjectKey() != null && !dto.getEvidenceObjectKey().isBlank()) {
            R2StorageService storage = storageServiceProvider.getIfAvailable();
            if (storage == null) throw new IllegalStateException("Cloudflare R2 chưa được cấu hình");
            evidenceUrl = storage.requireOwnedObject(reporter.getId(), "report", dto.getEvidenceObjectKey());
        }
        Report report = Report.builder()
                .reporter(reporter)
                .targetId(dto.getTargetId())
                .targetType(targetType)
                .reason(dto.getReason().trim())
                .evidenceUrl(evidenceUrl)
                .status("PENDING")
                .build();

        Report saved = reportRepository.save(report);

        Map<String, Object> response = new HashMap<>();
        response.put("reportId", saved.getId());
        response.put("status", saved.getStatus());
        response.put("message", "Đã tiếp nhận báo cáo để ban quản trị xem xét.");
        return response;
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));
    }
}
