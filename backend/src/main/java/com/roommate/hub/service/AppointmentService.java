package com.roommate.hub.service;

import com.roommate.hub.dto.AppointmentResponseDTO;
import com.roommate.hub.dto.CreateAppointmentDTO;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.entity.ViewingAppointment.AppointmentStatus;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final ViewingAppointmentRepository appointmentRepository;
    private final UserRepository userRepository;
    private final RoomPostRepository roomPostRepository;
    private final MatchRequestRepository matchRequestRepository;
    private final BlockedUserRepository blockedUserRepository;

    @Transactional
    public AppointmentResponseDTO createAppointment(CreateAppointmentDTO dto) {
        User requester = currentUser();
        RoomPost post = roomPostRepository.findById(dto.getRoomPostId())
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng phòng không tồn tại!"));

        assertCanArrangeViewing(requester, post.getAuthor(), post);

        if (dto.getAppointmentTime() == null || !dto.getAppointmentTime().isAfter(java.time.OffsetDateTime.now())) {
            throw new IllegalArgumentException("Thời gian xem phòng phải ở trong tương lai!");
        }

        if (post.getAuthor().getId().equals(requester.getId())) {
            throw new IllegalArgumentException("Bạn không thể tự đặt lịch xem phòng của chính mình!");
        }

        ViewingAppointment appointment = ViewingAppointment.builder()
                .requester(requester)
                .host(post.getAuthor())
                .roomPost(post)
                .appointmentTime(dto.getAppointmentTime())
                .status(AppointmentStatus.PENDING)
                .note(dto.getNote())
                .build();

        return toResponse(appointmentRepository.save(appointment));
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponseDTO> getMyAppointments() {
        User user = currentUser();
        return appointmentRepository.findAllByUserId(user.getId())
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public AppointmentResponseDTO updateStatus(Long appointmentId, String statusStr) {
        User user = currentUser();
        ViewingAppointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Lịch hẹn không tồn tại!"));

        boolean isHost = appointment.getHost().getId().equals(user.getId());
        boolean isRequester = appointment.getRequester().getId().equals(user.getId());

        if (!isHost && !isRequester) {
            throw new ForbiddenException("Bạn không có quyền thao tác lịch hẹn này!");
        }

        if (statusStr == null || statusStr.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Trạng thái lịch hẹn không được để trống!");
        }

        AppointmentStatus targetStatus;
        try {
            targetStatus = AppointmentStatus.valueOf(statusStr.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Trạng thái lịch hẹn không hợp lệ: " + statusStr);
        }
        AppointmentStatus current = appointment.getStatus();

        if (current == AppointmentStatus.CANCELLED) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Lịch hẹn đã bị hủy, không thể thay đổi trạng thái!");
        }
        if (current == AppointmentStatus.COMPLETED) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Lịch hẹn đã hoàn tất, không thể thay đổi trạng thái!");
        }

        // Repeated confirmations must not bypass role, blocks, locks or room eligibility.
        if (targetStatus == AppointmentStatus.CONFIRMED && !isHost) {
            throw new ForbiddenException("Chỉ chủ nhà mới có quyền xác nhận lịch hẹn!");
        }
        if (targetStatus == AppointmentStatus.COMPLETED && !isHost) {
            throw new ForbiddenException("Chỉ chủ nhà mới có quyền đánh dấu hoàn thành lịch hẹn!");
        }
        if (targetStatus == AppointmentStatus.CONFIRMED || targetStatus == AppointmentStatus.COMPLETED) {
            assertCanArrangeViewing(appointment.getRequester(), appointment.getHost(), appointment.getRoomPost());
        }

        if (targetStatus == current) {
            return toResponse(appointment);
        }

        if (targetStatus == AppointmentStatus.PENDING) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Không thể chuyển trạng thái lịch hẹn về trạng thái chờ duyệt!");
        }

        if (current == AppointmentStatus.PENDING && targetStatus == AppointmentStatus.COMPLETED) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Không thể hoàn tất lịch hẹn khi chưa được xác nhận!");
        }

        appointment.setStatus(targetStatus);
        return toResponse(appointmentRepository.save(appointment));
    }

    private void assertCanArrangeViewing(User requester, User host, RoomPost post) {
        if (!"ACTIVE".equalsIgnoreCase(requester.getStatus()) || !"ACTIVE".equalsIgnoreCase(host.getStatus())) {
            throw new ForbiddenException("Không thể thao tác lịch hẹn vì một tài khoản đã bị khóa hoặc chưa được kích hoạt!");
        }
        if (isBlocked(requester, host)) {
            throw new ForbiddenException("Không thể thao tác lịch hẹn vì hai người đã chặn nhau!");
        }
        if (post.getStatus() != RoomPost.PostStatus.APPROVED && post.getStatus() != RoomPost.PostStatus.AVAILABLE) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Tin phòng phải được duyệt và đang mở để tạo, xác nhận hoặc hoàn tất lịch hẹn!");
        }
    }

    private boolean isBlocked(User requester, User host) {
        return blockedUserRepository.existsByUserIdAndBlockedUserId(requester.getId(), host.getId())
                || blockedUserRepository.existsByUserIdAndBlockedUserId(host.getId(), requester.getId());
    }

    private AppointmentResponseDTO toResponse(ViewingAppointment appointment) {
        AppointmentResponseDTO response = AppointmentResponseDTO.from(appointment);
        User requester = appointment.getRequester();
        User host = appointment.getHost();

        if (!"ACTIVE".equalsIgnoreCase(requester.getStatus())
                || !"ACTIVE".equalsIgnoreCase(host.getStatus())
                || isBlocked(requester, host)) {
            return response;
        }

        // A confirmed viewing permits chat, not contact disclosure. Only the accepted connection grants it.
        boolean hasAcceptedConnection = matchRequestRepository
                .findConnectionBetweenUsers(requester.getId(), host.getId())
                .filter(request -> request.getStatus() == MatchRequest.MatchStatus.ACCEPTED)
                .isPresent();
        if (hasAcceptedConnection) {
            response.setRequesterPhone(requester.getPhone());
            response.setHostPhone(host.getPhone());
        }
        return response;
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));
    }
}
