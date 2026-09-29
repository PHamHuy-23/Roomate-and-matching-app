package com.roommate.hub.service;

import com.roommate.hub.dto.AppointmentResponseDTO;
import com.roommate.hub.dto.CreateAppointmentDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.entity.ViewingAppointment.AppointmentStatus;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
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

    @Transactional
    public AppointmentResponseDTO createAppointment(CreateAppointmentDTO dto) {
        User requester = currentUser();
        RoomPost post = roomPostRepository.findById(dto.getRoomPostId())
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng phòng không tồn tại!"));

        if (post.getAuthor().getId().equals(requester.getId())) {
            throw new RuntimeException("Bạn không thể tự đặt lịch xem phòng của chính mình!");
        }

        ViewingAppointment appointment = ViewingAppointment.builder()
                .requester(requester)
                .host(post.getAuthor())
                .roomPost(post)
                .appointmentTime(dto.getAppointmentTime())
                .status(AppointmentStatus.PENDING)
                .note(dto.getNote())
                .build();

        return AppointmentResponseDTO.from(appointmentRepository.save(appointment));
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponseDTO> getMyAppointments() {
        User user = currentUser();
        return appointmentRepository.findAllByUserId(user.getId())
                .stream()
                .map(AppointmentResponseDTO::from)
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

        AppointmentStatus targetStatus = AppointmentStatus.valueOf(statusStr.toUpperCase());
        appointment.setStatus(targetStatus);
        return AppointmentResponseDTO.from(appointmentRepository.save(appointment));
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));
    }
}
