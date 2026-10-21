package com.roommate.hub.service;

import com.roommate.hub.dto.SendMessageDTO;
import com.roommate.hub.entity.ChatMessage;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.MatchRequestRepository;
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

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verifyNoInteractions;

class ChatServiceTest {

    private final ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final BlockedUserRepository blockedUserRepository = mock(BlockedUserRepository.class);
    private final MatchRequestRepository matchRequestRepository = mock(MatchRequestRepository.class);
    private final ViewingAppointmentRepository viewingAppointmentRepository = mock(ViewingAppointmentRepository.class);
    @SuppressWarnings("unchecked")
    private final ObjectProvider<R2StorageService> storageProvider = mock(ObjectProvider.class);

    private final ChatService chatService = new ChatService(
            chatMessageRepository,
            userRepository,
            blockedUserRepository,
            matchRequestRepository,
            viewingAppointmentRepository,
            storageProvider
    );

    private final User sender = User.builder().id(1L).email("sender@example.com").build();
    private final User receiver = User.builder().id(2L).email("receiver@example.com").build();

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(sender.getEmail(), null, java.util.List.of())
        );
        when(userRepository.findByEmail(sender.getEmail())).thenReturn(Optional.of(sender));
        when(userRepository.findById(2L)).thenReturn(Optional.of(receiver));
        when(blockedUserRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(false);
        when(blockedUserRepository.existsByUserIdAndBlockedUserId(2L, 1L)).thenReturn(false);
        MatchRequest matchRequest = MatchRequest.builder()
                .sender(sender)
                .receiver(receiver)
                .status(MatchRequest.MatchStatus.ACCEPTED)
                .build();
        when(matchRequestRepository.findConnectionBetweenUsers(1L, 2L)).thenReturn(Optional.of(matchRequest));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void rejectsLockedReceiverBeforeSavingAnyMessage() {
        receiver.setStatus("LOCKED");
        SendMessageDTO dto = SendMessageDTO.builder().receiverId(2L).content("Hello").build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.FORBIDDEN));
        verifyNoInteractions(chatMessageRepository);
    }

    @Test
    void activeReceiverStillCannotReceiveChatWhenEitherUserHasBlockedTheOther() {
        SendMessageDTO dto = SendMessageDTO.builder().receiverId(2L).content("Hello").build();
        for (boolean senderBlocks : new boolean[]{true, false}) {
            when(blockedUserRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(senderBlocks);
            when(blockedUserRepository.existsByUserIdAndBlockedUserId(2L, 1L)).thenReturn(!senderBlocks);
            assertThatThrownBy(() -> chatService.sendMessage(dto))
                    .isInstanceOf(ResponseStatusException.class)
                    .satisfies(ex -> {
                        ResponseStatusException error = (ResponseStatusException) ex;
                        assertThat(error.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
                        assertThat(error.getReason()).contains("chặn nhau");
                    });
        }
        verifyNoInteractions(chatMessageRepository);
    }

    @Test
    void rejectsUntrustedExternalImageUrlInChat() {
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Hello")
                .imageUrl("https://malicious-tracker.evil.com/pixel.png")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                    assertThat(rse.getReason()).contains("không an toàn");
                });
    }

    @Test
    void rejectsPathTraversalImageUrlInChat() {
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Hello")
                .imageUrl("/uploads/../../secret.png")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                });
    }

    @Test
    void rejectsLegacyTrustedDomainImageUrlInChat() {
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Check this room")
                .imageUrl("https://images.roommatehub.com/uploads/photo.jpg")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.BAD_REQUEST));
        verifyNoInteractions(chatMessageRepository, storageProvider);
    }

    @Test
    void rejectsFakeSuffixDomainImageUrlInChat() {
        // Domain that ends with roommatehub.com but is an unauthorized domain
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Hello")
                .imageUrl("https://evilroommatehub.com/pixel.png")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                    assertThat(rse.getReason()).contains("không an toàn");
                });
    }

    @Test
    void rejectsArbitraryR2BucketImageUrlInChat() {
        // Arbitrary attacker Cloudflare R2 bucket
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Hello")
                .imageUrl("https://attacker-bucket.r2.cloudflarestorage.com/pixel.png")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                    assertThat(rse.getReason()).contains("không an toàn");
                });
    }

    @Test
    void rejectsLegacyAppR2BucketImageUrlInChat() {
        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Hello")
                .imageUrl("https://roommate-prod-bucket.r2.cloudflarestorage.com/uploads/photo.png")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.BAD_REQUEST));
        verifyNoInteractions(chatMessageRepository, storageProvider);
    }

    @Test
    void rejectsChatWhenAppointmentIsCancelledAndNotMatched() {
        // Không có quan hệ matched
        when(matchRequestRepository.findConnectionBetweenUsers(1L, 2L)).thenReturn(Optional.empty());

        com.roommate.hub.entity.ViewingAppointment cancelledAppt = com.roommate.hub.entity.ViewingAppointment.builder()
                .requester(sender)
                .host(receiver)
                .status(com.roommate.hub.entity.ViewingAppointment.AppointmentStatus.CANCELLED)
                .build();
        when(viewingAppointmentRepository.findAllByUserId(1L)).thenReturn(java.util.List.of(cancelledAppt));

        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Test message")
                .build();

        assertThatThrownBy(() -> chatService.sendMessage(dto))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
                    assertThat(rse.getReason()).contains("CONFIRMED");
                });
    }

    @Test
    void allowsChatWhenAppointmentIsConfirmedAndNotMatched() {
        // Không có quan hệ matched nhưng có lịch hẹn CONFIRMED
        when(matchRequestRepository.findConnectionBetweenUsers(1L, 2L)).thenReturn(Optional.empty());

        com.roommate.hub.entity.ViewingAppointment confirmedAppt = com.roommate.hub.entity.ViewingAppointment.builder()
                .requester(sender)
                .host(receiver)
                .status(com.roommate.hub.entity.ViewingAppointment.AppointmentStatus.CONFIRMED)
                .build();
        when(viewingAppointmentRepository.findAllByUserId(1L)).thenReturn(java.util.List.of(confirmedAppt));

        SendMessageDTO dto = SendMessageDTO.builder()
                .receiverId(2L)
                .content("Lịch hẹn đã xác nhận, chào bạn!")
                .build();

        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(invocation -> {
            ChatMessage msg = invocation.getArgument(0);
            return ChatMessage.builder()
                    .id(102L)
                    .sender(msg.getSender())
                    .receiver(msg.getReceiver())
                    .content(msg.getContent())
                    .build();
        });

        var result = chatService.sendMessage(dto);
        assertThat(result).isNotNull();
        assertThat(result.getContent()).isEqualTo("Lịch hẹn đã xác nhận, chào bạn!");
    }
}
