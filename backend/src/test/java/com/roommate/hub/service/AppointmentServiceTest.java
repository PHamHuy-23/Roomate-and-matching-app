package com.roommate.hub.service;

import com.roommate.hub.dto.AppointmentResponseDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.entity.ViewingAppointment.AppointmentStatus;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTest {

    @Mock
    private ViewingAppointmentRepository appointmentRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoomPostRepository roomPostRepository;

    @Mock
    private MatchRequestRepository matchRequestRepository;

    @Mock
    private BlockedUserRepository blockedUserRepository;

    @InjectMocks
    private AppointmentService appointmentService;

    private User hostUser;
    private User requesterUser;
    private RoomPost samplePost;
    private ViewingAppointment appointment;

    @BeforeEach
    void setUp() {
        hostUser = User.builder().id(1L).email("host@example.com").fullName("Chủ nhà").build();
        requesterUser = User.builder().id(2L).email("requester@example.com").fullName("Người thuê").build();
        samplePost = RoomPost.builder().id(10L).title("Phòng trọ").author(hostUser)
                .status(RoomPost.PostStatus.APPROVED).build();

        appointment = ViewingAppointment.builder()
                .id(100L)
                .host(hostUser)
                .requester(requesterUser)
                .roomPost(samplePost)
                .appointmentTime(java.time.OffsetDateTime.now().plusDays(2))
                .status(AppointmentStatus.PENDING)
                .build();

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(hostUser.getEmail(), null, List.of())
        );

        lenient().when(userRepository.findByEmail("host@example.com")).thenReturn(Optional.of(hostUser));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("DTO mặc định không tự tiết lộ điện thoại dù entity có dữ liệu")
    void defaultResponseMapper_ShouldHideBothPhones() {
        requesterUser.setPhone("0000000001");
        hostUser.setPhone("0000000002");

        AppointmentResponseDTO response = AppointmentResponseDTO.from(appointment);

        assertThat(response.getRequesterPhone()).isNull();
        assertThat(response.getHostPhone()).isNull();
        assertThat(response.getRequesterId()).isEqualTo(requesterUser.getId());
        assertThat(response.getHostId()).isEqualTo(hostUser.getId());
        assertThat(response.getRoomPostId()).isEqualTo(samplePost.getId());
    }

    @Test
    @DisplayName("updateStatus() ném ngoại lệ khi chuyển ngược trạng thái CANCELLED")
    void updateStatus_WhenAlreadyCancelled_ShouldThrowBadRequest() {
        appointment.setStatus(AppointmentStatus.CANCELLED);
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "PENDING"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Lịch hẹn đã bị hủy");
    }

    @Test
    @DisplayName("updateStatus() ném ngoại lệ khi chuyển ngược trạng thái COMPLETED")
    void updateStatus_WhenAlreadyCompleted_ShouldThrowBadRequest() {
        appointment.setStatus(AppointmentStatus.COMPLETED);
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "CONFIRMED"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Lịch hẹn đã hoàn tất");
    }

    @Test
    @DisplayName("updateStatus() ném ngoại lệ khi chuyển trạng thái về PENDING")
    void updateStatus_WhenTargetIsPending_ShouldThrowBadRequest() {
        appointment.setStatus(AppointmentStatus.CONFIRMED);
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "PENDING"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Không thể chuyển trạng thái lịch hẹn về trạng thái chờ duyệt");
    }

    @Test
    @DisplayName("updateStatus() ném ngoại lệ khi chuyển từ PENDING thẳng sang COMPLETED")
    void updateStatus_WhenPendingToCompleted_ShouldThrowBadRequest() {
        appointment.setStatus(AppointmentStatus.PENDING);
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "COMPLETED"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Không thể hoàn tất lịch hẹn khi chưa được xác nhận");
    }

    @Test
    @DisplayName("updateStatus() chuyển thành công từ PENDING sang CONFIRMED bởi chủ nhà")
    void updateStatus_WhenPendingToConfirmed_ShouldSucceed() {
        appointment.setStatus(AppointmentStatus.PENDING);
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(ViewingAppointment.class))).thenAnswer(inv -> inv.getArgument(0));

        AppointmentResponseDTO response = appointmentService.updateStatus(100L, "CONFIRMED");

        assertThat(response.getStatus()).isEqualTo("CONFIRMED");
        verify(appointmentRepository, times(1)).save(appointment);
    }

    @Test
    @DisplayName("updateStatus() ném BAD_REQUEST khi statusStr rỗng hoặc null")
    void updateStatus_WhenStatusBlankOrNull_ShouldThrowBadRequest() {
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, null))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(org.springframework.http.HttpStatus.BAD_REQUEST))
                .hasMessageContaining("không được để trống");

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "   "))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(org.springframework.http.HttpStatus.BAD_REQUEST))
                .hasMessageContaining("không được để trống");
    }

    @Test
    @DisplayName("updateStatus() ném BAD_REQUEST khi statusStr không hợp lệ")
    void updateStatus_WhenStatusInvalid_ShouldThrowBadRequest() {
        when(appointmentRepository.findByIdForStatusUpdate(100L)).thenReturn(Optional.of(appointment));

        assertThatThrownBy(() -> appointmentService.updateStatus(100L, "UNKNOWN_STATUS"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(org.springframework.http.HttpStatus.BAD_REQUEST))
                .hasMessageContaining("Trạng thái lịch hẹn không hợp lệ");
    }

    @Test
    @DisplayName("createAppointment() ném ngoại lệ khi appointmentTime ở quá khứ")
    void createAppointment_WhenPastTime_ShouldThrowRuntimeException() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(requesterUser.getEmail(), null, List.of())
        );
        when(userRepository.findByEmail(requesterUser.getEmail())).thenReturn(Optional.of(requesterUser));
        samplePost.setStatus(RoomPost.PostStatus.APPROVED);
        when(roomPostRepository.findById(10L)).thenReturn(Optional.of(samplePost));

        com.roommate.hub.dto.CreateAppointmentDTO dto = com.roommate.hub.dto.CreateAppointmentDTO.builder()
                .roomPostId(10L)
                .appointmentTime(java.time.OffsetDateTime.now().minusMinutes(10))
                .build();

        assertThatThrownBy(() -> appointmentService.createAppointment(dto))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Thời gian xem phòng phải ở trong tương lai");
    }

    @Test
    @DisplayName("createAppointment() thành công khi appointmentTime ở tương lai với timezone offset")
    void createAppointment_WhenFutureTime_ShouldSucceed() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(requesterUser.getEmail(), null, List.of())
        );
        when(userRepository.findByEmail(requesterUser.getEmail())).thenReturn(Optional.of(requesterUser));
        samplePost.setStatus(RoomPost.PostStatus.APPROVED);
        when(roomPostRepository.findById(10L)).thenReturn(Optional.of(samplePost));
        when(appointmentRepository.save(any(ViewingAppointment.class))).thenAnswer(inv -> {
            ViewingAppointment a = inv.getArgument(0);
            a.setId(200L);
            return a;
        });

        com.roommate.hub.dto.CreateAppointmentDTO dto = com.roommate.hub.dto.CreateAppointmentDTO.builder()
                .roomPostId(10L)
                .appointmentTime(java.time.OffsetDateTime.now().plusDays(1))
                .build();

        var result = appointmentService.createAppointment(dto);
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(200L);
        assertThat(result.getStatus()).isEqualTo("PENDING");
    }
}
