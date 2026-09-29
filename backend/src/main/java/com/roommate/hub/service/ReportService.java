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

    @Transactional
    public Map<String, Object> createReport(CreateReportDTO dto) {
        User reporter = currentUser();

        Report report = Report.builder()
                .reporter(reporter)
                .targetId(dto.getTargetId())
                .targetType(dto.getTargetType() != null ? dto.getTargetType().toUpperCase() : "USER")
                .reason(dto.getReason().trim())
                .status("PENDING")
                .build();

        Report saved = reportRepository.save(report);

        Map<String, Object> response = new HashMap<>();
        response.put("reportId", saved.getId());
        response.put("status", saved.getStatus());
        response.put("message", "Đã tiếp nhận báo cáo. Ban quản trị sẽ xử lý trong 24 giờ.");
        return response;
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));
    }
}
