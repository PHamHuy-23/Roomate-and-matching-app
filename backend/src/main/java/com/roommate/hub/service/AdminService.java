package com.roommate.hub.service;

import com.roommate.hub.dto.AdminReportResponseDTO;
import com.roommate.hub.dto.AdminPostResponseDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.entity.Report;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final RoomPostRepository roomPostRepository;
    private final UserRepository userRepository;
    private final ReportRepository reportRepository;
    private final ObjectProvider<R2StorageService> storageServiceProvider;

    // Lấy toàn bộ bài đăng kèm trạng thái để kiểm duyệt
    public List<AdminPostResponseDTO> getAllPostsForModeration() {
        return roomPostRepository.findAll().stream().map(AdminPostResponseDTO::from).toList();
    }

    // Duyệt hoặc từ chối bài đăng
    @Transactional
    public RoomPost moderatePost(Long postId, String status) {
        return moderatePost(postId, status, null);
    }

    @Transactional
    public RoomPost moderatePost(Long postId, String status, String reason) {
        RoomPost post = roomPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng không tồn tại!"));

        if (status == null || !List.of("APPROVED", "REJECTED", "CLOSED").contains(status.toUpperCase())) {
            throw new IllegalArgumentException("Trạng thái kiểm duyệt không hợp lệ");
        }
        post.setStatus(RoomPost.PostStatus.valueOf(status.toUpperCase()));
        post.setModerationReason(reason == null || reason.isBlank() ? null : reason.trim());
        return roomPostRepository.save(post);
    }

    // Lấy danh sách toàn bộ người dùng
    public List<UserResponseDTO> getAllUsers() {
        return userRepository.findAll().stream().map(UserResponseDTO::from).toList();
    }

    public UserResponseDTO getUser(Long userId) {
        return UserResponseDTO.from(userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!")));
    }

    // Đặt trạng thái đích; gửi lại cùng lệnh không đảo trạng thái tài khoản.
    @Transactional
    public Map<String, Object> setUserStatus(Long userId, String status) {
        if (status == null || !List.of("ACTIVE", "LOCKED").contains(status)) {
            throw new IllegalArgumentException("Trạng thái tài khoản phải là ACTIVE hoặc LOCKED");
        }
        Authentication actor = SecurityContextHolder.getContext().getAuthentication();
        if (actor == null || !actor.isAuthenticated()
                || actor.getAuthorities().stream().noneMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()))) {
            throw new ForbiddenException("Chỉ quản trị viên mới được thay đổi trạng thái tài khoản!");
        }
        User user = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));

        if (user.getEmail().equals(actor.getName())) {
            throw new ForbiddenException("Bạn không được thay đổi trạng thái chính tài khoản đang đăng nhập!");
        }

        if (!status.equals(user.getStatus())) {
            user.setStatus(status);
            userRepository.save(user);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("userId", user.getId());
        res.put("status", user.getStatus());
        return res;
    }

    // Lấy toàn bộ danh sách báo cáo
    @Transactional(readOnly = true)
    public List<AdminReportResponseDTO> getAllReports() {
        return reportRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(this::reportResponse)
                .toList();
    }

    // Duyệt / xử lý báo cáo vi phạm
    @Transactional
    public AdminReportResponseDTO moderateReport(Long reportId, String status, String note) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("Báo cáo không tồn tại!"));
        if (status == null || !List.of("PENDING", "RESOLVED", "DISMISSED").contains(status.toUpperCase())) {
            throw new IllegalArgumentException("Trạng thái báo cáo không hợp lệ");
        }
        report.setStatus(status.toUpperCase());
        if (note != null && !note.isBlank()) {
            report.setActionNote(note.trim());
        }
        return reportResponse(reportRepository.save(report));
    }

    private AdminReportResponseDTO reportResponse(Report report) {
        AdminReportResponseDTO response = AdminReportResponseDTO.from(report);
        Authentication actor = SecurityContextHolder.getContext().getAuthentication();
        boolean authorized = actor != null && actor.isAuthenticated()
                && actor.getAuthorities().stream().anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()))
                && userRepository.findByEmail(actor.getName())
                        .filter(user -> "ACTIVE".equalsIgnoreCase(user.getStatus()) && user.getRole() == User.Role.ROLE_ADMIN)
                        .isPresent();
        Long ownerId = report.getReporter() == null ? null : report.getReporter().getId();
        if (authorized && R2StorageService.isOwnedPrivateObject(ownerId, "report", report.getEvidenceUrl())) {
            R2StorageService storage = storageServiceProvider.getIfAvailable();
            if (storage != null) {
                try {
                    response.setEvidenceUrl(storage.privateReadUrl(ownerId, "report", report.getEvidenceUrl()));
                } catch (org.springframework.web.server.ResponseStatusException error) {
                    if (error.getStatusCode().value() != 503) throw error;
                    // Keep the report readable without exposing a public fallback when storage is unavailable.
                }
            }
        }
        return response;
    }
}
