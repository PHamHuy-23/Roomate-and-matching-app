package com.roommate.hub.service;

import com.roommate.hub.dto.AdminReportResponseDTO;
import com.roommate.hub.dto.AdminPostResponseDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.entity.Report;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
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
                .orElseThrow(() -> new RuntimeException("Bài đăng không tồn tại!"));

        post.setStatus(RoomPost.PostStatus.valueOf(status.toUpperCase()));
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

    // Khóa hoặc mở khóa người dùng
    @Transactional
    public Map<String, Object> toggleUserStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));

        // Nếu trạng thái đang là ACTIVE thì đổi thành LOCKED và ngược lại
        String newStatus = "ACTIVE".equalsIgnoreCase(user.getStatus()) ? "LOCKED" : "ACTIVE";
        user.setStatus(newStatus);
        userRepository.save(user);

        Map<String, Object> res = new HashMap<>();
        res.put("userId", user.getId());
        res.put("status", newStatus);
        return res;
    }

    // Lấy toàn bộ danh sách báo cáo
    public List<AdminReportResponseDTO> getAllReports() {
        return reportRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(AdminReportResponseDTO::from)
                .toList();
    }

    // Duyệt / xử lý báo cáo vi phạm
    @Transactional
    public AdminReportResponseDTO moderateReport(Long reportId, String status, String note) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("Báo cáo không tồn tại!"));
        report.setStatus(status.toUpperCase());
        if (note != null && !note.isBlank()) {
            report.setActionNote(note.trim());
        }
        return AdminReportResponseDTO.from(reportRepository.save(report));
    }
}
