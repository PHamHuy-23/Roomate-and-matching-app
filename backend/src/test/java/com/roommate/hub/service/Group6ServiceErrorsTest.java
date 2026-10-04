package com.roommate.hub.service;

import com.roommate.hub.controller.MatchController;
import com.roommate.hub.dto.CreateAppointmentDTO;
import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.dto.SendMessageDTO;
import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class Group6ServiceErrorsTest {
    private final UserRepository users = mock(UserRepository.class);
    private final RoomPostRepository posts = mock(RoomPostRepository.class);
    private final ViewingAppointmentRepository appointments = mock(ViewingAppointmentRepository.class);
    private final MatchRequestRepository matches = mock(MatchRequestRepository.class);
    private final BlockedUserRepository blocks = mock(BlockedUserRepository.class);
    private final ChatMessageRepository messages = mock(ChatMessageRepository.class);
    private final UserPreferenceRepository preferences = mock(UserPreferenceRepository.class);
    private final MatchingService matching = mock(MatchingService.class);
    @SuppressWarnings("unchecked")
    private final ObjectProvider<R2StorageService> storage = mock(ObjectProvider.class);

    private final AppointmentService appointmentService =
            new AppointmentService(appointments, users, posts, matches, blocks);
    private final ChatService chatService =
            new ChatService(messages, users, blocks, matches, appointments, storage);
    private final MatchRequestService matchService = new MatchRequestService(matches, users, matching, blocks);
    private final ProfileService profileService = new ProfileService(preferences, users, blocks);
    private final RoomPostService roomService = new RoomPostService(posts, users, storage);
    private final User actor = User.builder().id(1L).email("actor@example.com").status("ACTIVE").build();
    private final User host = User.builder().id(2L).email("host@example.com").status("ACTIVE").build();

    @BeforeEach
    void authenticate() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(actor.getEmail(), null, List.of()));
        when(users.findByEmail(actor.getEmail())).thenReturn(Optional.of(actor));
    }

    @AfterEach
    void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void pastAppointmentTimeIsAnExplicitBadRequestWithoutSaving() {
        availableRoom(host);
        CreateAppointmentDTO request = appointmentRequest(OffsetDateTime.now().minusDays(1));

        assertThatThrownBy(() -> appointmentService.createAppointment(request))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Thời gian xem phòng phải ở trong tương lai!");
        verifyNoInteractions(appointments);
    }

    @Test
    void missingAppointmentTimeIsAnExplicitBadRequestWithoutSaving() {
        availableRoom(host);

        assertThatThrownBy(() -> appointmentService.createAppointment(appointmentRequest(null)))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Thời gian xem phòng phải ở trong tương lai!");
        verifyNoInteractions(appointments);
    }

    @Test
    void selfAppointmentIsAnExplicitBadRequestWithoutSaving() {
        availableRoom(actor);

        assertThatThrownBy(() -> appointmentService.createAppointment(appointmentRequest(OffsetDateTime.now().plusDays(1))))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Bạn không thể tự đặt lịch xem phòng của chính mình!");
        verifyNoInteractions(appointments);
    }

    @Test
    void selfChatIsAnExplicitBadRequestBeforeConnectionAndStorageChecks() {
        when(users.findById(actor.getId())).thenReturn(Optional.of(actor));

        assertThatThrownBy(() -> chatService.sendMessage(
                SendMessageDTO.builder().receiverId(actor.getId()).content("Hello").build()))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Bạn không thể tự gửi tin nhắn cho chính mình!");
        verifyNoInteractions(messages, matches, appointments, blocks, storage);
    }

    @Test
    void selfMatchIsAnExplicitBadRequestBeforeLockingAndSaving() {
        assertThatThrownBy(() -> matchService.sendRequest(actor.getId(), actor.getId()))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Không thể tự ghép đôi với chính mình!");
        verifyNoInteractions(matches, matching, blocks);
        verify(users, never()).findByIdForUpdate(any());
    }

    @Test
    void savingPreferencesForMissingUserIsExplicitlyNotFound() {
        when(users.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> profileService.saveOrUpdatePreferences(99L, UserPreferenceDTO.builder().build()))
                .isExactlyInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Người dùng không tồn tại!");
        verifyNoInteractions(preferences);
    }

    @Test
    void recommendationUserDisappearingAfterIdentityCheckIsExplicitlyNotFound() {
        MatchController controller = new MatchController(matching, matchService, users);
        when(users.findById(actor.getId())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> controller.getRecommendations(actor.getId()))
                .isExactlyInstanceOf(ResourceNotFoundException.class)
                .hasMessage("User không tồn tại!");
        verifyNoInteractions(matching);
    }

    @Test
    void creatingPostWithAnImageAndMissingStorageIsServiceUnavailableWithoutSaving() {
        CreateRoomPostDTO request = new CreateRoomPostDTO();
        request.setMaxOccupants(2);
        request.setImageObjectKey("room-posts/1/00000000-0000-4000-8000-000000000001.jpg");

        assertThatThrownBy(() -> roomService.createPost(request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(error -> assertThat(((ResponseStatusException) error).getStatusCode())
                        .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE))
                .hasMessageContaining("Cloudflare R2 chưa được cấu hình");
        verifyNoInteractions(posts);
    }

    @Test
    void updatingPostWithAnImageAndMissingStorageIsServiceUnavailableWithoutSaving() {
        RoomPost post = RoomPost.builder().id(10L).author(actor).maxOccupants(2).currentOccupants(0)
                .status(RoomPost.PostStatus.APPROVED).imageUrl("https://media.example.com/old.jpg").build();
        when(posts.findById(10L)).thenReturn(Optional.of(post));
        CreateRoomPostDTO request = new CreateRoomPostDTO();
        request.setImageObjectKey("room-posts/1/00000000-0000-4000-8000-000000000001.jpg");

        assertThatThrownBy(() -> roomService.updatePost(10L, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(error -> assertThat(((ResponseStatusException) error).getStatusCode())
                        .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE))
                .hasMessageContaining("Cloudflare R2 chưa được cấu hình");
        verify(posts, never()).save(any());
        assertThat(post.getImageUrl()).isEqualTo("https://media.example.com/old.jpg");
        assertThat(post.getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
    }

    private void availableRoom(User author) {
        when(posts.findById(10L)).thenReturn(Optional.of(RoomPost.builder()
                .id(10L).author(author).status(RoomPost.PostStatus.APPROVED).build()));
    }

    private CreateAppointmentDTO appointmentRequest(OffsetDateTime appointmentTime) {
        return CreateAppointmentDTO.builder().roomPostId(10L).appointmentTime(appointmentTime).build();
    }
}
