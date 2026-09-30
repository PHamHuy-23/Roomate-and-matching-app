package com.roommate.hub.service;

import com.roommate.hub.dto.MatchRequestResponseDTO;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MatchRequestServiceTest {

    @Mock
    private MatchRequestRepository matchRequestRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private MatchingService matchingService;

    @Mock
    private com.roommate.hub.repository.BlockedUserRepository blockedUserRepository;

    @InjectMocks
    private MatchRequestService matchRequestService;

    private User userA;
    private User userB;

    @BeforeEach
    void setUp() {
        userA = User.builder().id(1L).fullName("User A").phone("0901234567").email("a@example.com").status("ACTIVE").build();
        userB = User.builder().id(2L).fullName("User B").phone("0907654321").email("b@example.com").status("ACTIVE").build();

        lenient().when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        lenient().when(userRepository.findById(2L)).thenReturn(Optional.of(userB));
        lenient().when(userRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(userA));
        lenient().when(userRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(userB));
        lenient().when(matchingService.getRecommendations(userA)).thenReturn(List.of());
        lenient().when(blockedUserRepository.existsByUserIdAndBlockedUserId(any(), any())).thenReturn(false);
    }

    @Test
    @DisplayName("sendRequest() tái sử dụng yêu cầu khi đối phương đã gửi yêu cầu trước đó")
    void sendRequest_WhenReverseRequestExists_ShouldAutoAcceptWithoutDuplicateRecord() {
        MatchRequest reverseRequest = MatchRequest.builder()
                .id(99L)
                .sender(userB)
                .receiver(userA)
                .matchScore(85.0)
                .status(MatchRequest.MatchStatus.PENDING)
                .build();

        when(matchRequestRepository.findConnectionBetweenUsers(1L, 2L)).thenReturn(Optional.of(reverseRequest));

        MatchRequestResponseDTO result = matchRequestService.sendRequest(1L, 2L);

        assertThat(result.getRequestId()).isEqualTo(99L);
        assertThat(result.getPartnerId()).isEqualTo(2L);
        assertThat(result.getStatus()).isEqualTo(MatchRequest.MatchStatus.PENDING.name());
    }

    @Test
    @DisplayName("cancelConnection() xóa toàn bộ bản ghi kết nối giữa 2 người dùng")
    void cancelConnection_ShouldDeleteAllConnectionsBetweenUsers() {
        MatchRequest r1 = MatchRequest.builder().id(10L).sender(userA).receiver(userB).build();
        MatchRequest r2 = MatchRequest.builder().id(11L).sender(userB).receiver(userA).build();

        when(matchRequestRepository.findAllBetweenUsers(1L, 2L)).thenReturn(List.of(r1, r2));

        matchRequestService.cancelConnection(1L, 2L);

        verify(matchRequestRepository, times(1)).deleteAll(List.of(r1, r2));
    }

    @Test
    @DisplayName("sendRequest() cho phép gửi lại khi yêu cầu cùng chiều từng bị REJECTED")
    void sendRequest_WhenDirectWasRejected_ShouldResetToPending() {
        MatchRequest rejectedDirect = MatchRequest.builder()
                .id(201L)
                .sender(userA)
                .receiver(userB)
                .matchScore(70.0)
                .status(MatchRequest.MatchStatus.REJECTED)
                .build();

        when(matchRequestRepository.findConnectionBetweenUsers(1L, 2L)).thenReturn(Optional.of(rejectedDirect));
        when(matchRequestRepository.save(any(MatchRequest.class))).thenAnswer(inv -> inv.getArgument(0));

        MatchRequestResponseDTO result = matchRequestService.sendRequest(1L, 2L);

        // Chuyển lại về PENDING thành công
        assertThat(result.getStatus()).isEqualTo(MatchRequest.MatchStatus.PENDING.name());
        assertThat(rejectedDirect.getStatus()).isEqualTo(MatchRequest.MatchStatus.PENDING);
        verify(matchRequestRepository, times(1)).save(rejectedDirect);
    }

    @Test
    @DisplayName("sendRequest() khi B gửi lại cho A sau khi A->B bị REJECTED phải đảo sender/receiver thành B->A")
    void sendRequest_WhenReverseWasRejected_ShouldFlipSenderReceiverAndResetToPending() {
        MatchRequest rejectedDirect = MatchRequest.builder()
                .id(202L)
                .sender(userA)
                .receiver(userB)
                .matchScore(70.0)
                .status(MatchRequest.MatchStatus.REJECTED)
                .build();

        when(matchRequestRepository.findConnectionBetweenUsers(2L, 1L)).thenReturn(Optional.of(rejectedDirect));
        when(matchRequestRepository.save(any(MatchRequest.class))).thenAnswer(inv -> inv.getArgument(0));

        MatchRequestResponseDTO result = matchRequestService.sendRequest(2L, 1L);

        assertThat(result.getRequestId()).isEqualTo(202L);
        assertThat(result.getPartnerId()).isEqualTo(1L);
        assertThat(result.getStatus()).isEqualTo(MatchRequest.MatchStatus.PENDING.name());
        assertThat(rejectedDirect.getSender()).isEqualTo(userB);
        assertThat(rejectedDirect.getReceiver()).isEqualTo(userA);
        assertThat(rejectedDirect.getStatus()).isEqualTo(MatchRequest.MatchStatus.PENDING);
        assertThat(rejectedDirect.getCreatedAt()).isNotNull();
        verify(matchRequestRepository, times(1)).save(rejectedDirect);
    }

    @Test
    @DisplayName("respondRequest() ném lỗi khi yêu cầu đã ở trạng thái ACCEPTED hoặc REJECTED")
    void respondRequest_WhenAlreadyFinalized_ShouldThrowBadRequest() {
        MatchRequest acceptedRequest = MatchRequest.builder()
                .id(301L)
                .sender(userA)
                .receiver(userB)
                .status(MatchRequest.MatchStatus.ACCEPTED)
                .build();

        when(matchRequestRepository.findByIdForUpdate(301L)).thenReturn(Optional.of(acceptedRequest));

        org.assertj.core.api.Assertions.assertThatThrownBy(
                () -> matchRequestService.respondRequest(301L, false, 2L)
        ).isInstanceOf(IllegalArgumentException.class);

        // Đảm bảo trạng thái không bị thay đổi ngoài ý muốn
        assertThat(acceptedRequest.getStatus()).isEqualTo(MatchRequest.MatchStatus.ACCEPTED);
        verify(matchRequestRepository, never()).save(any());
    }
}
