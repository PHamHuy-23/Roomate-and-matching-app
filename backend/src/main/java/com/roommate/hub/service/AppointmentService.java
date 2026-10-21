package com.roommate.hub.service;

import com.roommate.hub.dto.AppointmentResponseDTO;
import com.roommate.hub.dto.CreateAppointmentDTO;
import com.roommate.hub.dto.RescheduleAppointmentDTO;
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
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AppointmentService {

    private final ViewingAppointmentRepository appointmentRepository;
    private final UserRepository userRepository;
    private final RoomPostRepository roomPostRepository;
    private final MatchRequestRepository matchRequestRepository;
    private final BlockedUserRepository blockedUserRepository;
    private final EmailService emailService;

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
    public AppointmentResponseDTO rescheduleAppointment(Long appointmentId, RescheduleAppointmentDTO dto) {
        User user = currentUser();
        ViewingAppointment appointment = appointmentRepository.findByIdForStatusUpdate(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Lịch hẹn không tồn tại!"));

        boolean isHost = appointment.getHost().getId().equals(user.getId());
        if (!isHost) {
            throw new ForbiddenException("Chỉ chủ nhà mới có quyền đề xuất đổi giờ hẹn!");
        }

        if (appointment.getStatus() != AppointmentStatus.PENDING) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Chỉ có thể đề xuất đổi giờ khi lịch hẹn đang ở trạng thái chờ duyệt (PENDING)!");
        }

        if (appointment.isRescheduledOnce()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Cuộc hẹn này đã được đề xuất đổi giờ một lần. Không thể đổi thêm!");
        }

        if (dto.getNewAppointmentTime() == null || !dto.getNewAppointmentTime().isAfter(Instant.now())) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Thời gian đề xuất mới phải ở tương lai!");
        }

        assertCanArrangeViewing(appointment.getRequester(), appointment.getHost(), appointment.getRoomPost());

        OffsetDateTime newOffsetTime = dto.getNewAppointmentTime().atOffset(ZoneOffset.UTC);
        appointment.setAppointmentTime(newOffsetTime);
        appointment.setRescheduleReason(dto.getNote());
        appointment.setStatus(AppointmentStatus.RESCHEDULED);
        appointment.setRescheduledOnce(true);
        appointment.setReminderSent(false);

        ViewingAppointment saved = appointmentRepository.save(appointment);

        try {
            User requester = saved.getRequester();
            if (requester != null && requester.getEmail() != null) {
                String roomTitle = saved.getRoomPost() != null ? saved.getRoomPost().getTitle() : "Tin đăng phòng";
                emailService.sendAppointmentRescheduledNotification(
                        requester.getEmail(),
                        requester.getFullName(),
                        saved.getHost().getFullName(),
                        roomTitle,
                        dto.getNewAppointmentTime(),
                        dto.getNote()
                );
            }
        } catch (Exception e) {
            log.error("[APPOINTMENT RESCHEDULE] Lỗi khi gửi email thông báo đề xuất đổi giờ cho requester: {}", e.getMessage());
        }

        return toResponse(saved);
    }

    @Transactional
    public AppointmentResponseDTO updateStatus(Long appointmentId, String statusStr) {
        User user = currentUser();
        ViewingAppointment appointment = appointmentRepository.findByIdForStatusUpdate(appointmentId)
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

        if (current == AppointmentStatus.RESCHEDULED) {
            // Khi lịch hẹn đang ở trạng thái RESCHEDULED:
            // Chỉ requester mới có quyền phản hồi: Chấp nhận (CONFIRMED) hoặc Từ chối (CANCELLED)
            if (!isRequester) {
                throw new ForbiddenException("Chỉ người đặt lịch mới có quyền phản hồi đề xuất đổi giờ hẹn!");
            }
            if (targetStatus != AppointmentStatus.CONFIRMED && targetStatus != AppointmentStatus.CANCELLED) {
                throw new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.BAD_REQUEST,
                        "Đối với lịch hẹn được đề xuất đổi giờ, chỉ có thể xác nhận (CONFIRMED) hoặc hủy (CANCELLED)!");
            }
        }

        // Repeated confirmations must not bypass role, blocks, locks or room eligibility.
        if (targetStatus == AppointmentStatus.CONFIRMED && !isHost && current != AppointmentStatus.RESCHEDULED) {
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
        if (targetStatus == AppointmentStatus.RESCHEDULED) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Vui lòng sử dụng tính năng đề xuất đổi giờ hẹn riêng biệt!");
        }

        if (current == AppointmentStatus.PENDING && targetStatus == AppointmentStatus.COMPLETED) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Không thể hoàn tất lịch hẹn khi chưa được xác nhận!");
        }

        appointment.setStatus(targetStatus);
        // Khi ca hai xac nhan hoan tat o ghep (COMPLETED), tu dong cong so nguoi o va tru so cho trong
        if (targetStatus == AppointmentStatus.COMPLETED && appointment.getRoomPost() != null) {
            RoomPost post = appointment.getRoomPost();
            int currentOcc = post.getCurrentOccupants() != null ? post.getCurrentOccupants() : 0;
            int maxOcc = post.getMaxOccupants() != null ? post.getMaxOccupants() : 1;
            if (currentOcc < maxOcc) {
                post.setCurrentOccupants(currentOcc + 1);
            }
            if (post.getCurrentOccupants() >= maxOcc) {
                post.setStatus(RoomPost.PostStatus.CLOSED);
            }
            roomPostRepository.save(post);
        }
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

    @Scheduled(cron = "0 */15 * * * ?")
    @Transactional
    public void sendUpcomingAppointmentReminders() {
        Instant now = Instant.now();
        Instant reminderWindowEnd = now.plus(24, ChronoUnit.HOURS);
        OffsetDateTime startOffset = now.atOffset(ZoneOffset.UTC);
        OffsetDateTime endOffset = reminderWindowEnd.atOffset(ZoneOffset.UTC);

        List<ViewingAppointment> upcomingAppointments = appointmentRepository
                .findByStatusAndReminderSentFalseAndAppointmentTimeBetween(
                        AppointmentStatus.CONFIRMED,
                        startOffset,
                        endOffset
                );

        for (ViewingAppointment appointment : upcomingAppointments) {
            try {
                User requester = appointment.getRequester();
                User host = appointment.getHost();
                RoomPost post = appointment.getRoomPost();

                String roomTitle = post != null ? post.getTitle() : "Phòng cho thuê";
                String address = post != null ? post.getAddress() : "Chưa cập nhật địa chỉ";
                Instant appointmentInstant = appointment.getAppointmentTime() != null
                        ? appointment.getAppointmentTime().toInstant()
                        : null;

                // Gửi email nhắc nhở cho requester
                if (requester != null && requester.getEmail() != null) {
                    emailService.sendAppointmentReminder(
                            requester.getEmail(),
                            requester.getFullName(),
                            host != null ? host.getFullName() : "Chủ phòng",
                            roomTitle,
                            appointmentInstant,
                            address
                    );
                }

                // Gửi email nhắc nhở cho host
                if (host != null && host.getEmail() != null) {
                    emailService.sendAppointmentReminder(
                            host.getEmail(),
                            host.getFullName(),
                            requester != null ? requester.getFullName() : "Người xem phòng",
                            roomTitle,
                            appointmentInstant,
                            address
                    );
                }

                appointment.setReminderSent(true);
                appointmentRepository.save(appointment);
                log.info("[APPOINTMENT REMINDER] Đã gửi nhắc hẹn 24h cho cuộc hẹn ID {}", appointment.getId());
            } catch (Exception e) {
                log.error("[APPOINTMENT REMINDER] Lỗi khi gửi nhắc hẹn cho cuộc hẹn ID {}: {}", appointment.getId(), e.getMessage(), e);
            }
        }
    }
}
