package com.roommate.hub.service;

import com.roommate.hub.dto.ChatMessageDTO;
import com.roommate.hub.dto.SendMessageDTO;
import com.roommate.hub.entity.ChatMessage;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final BlockedUserRepository blockedUserRepository;
    private final MatchRequestRepository matchRequestRepository;
    private final ViewingAppointmentRepository viewingAppointmentRepository;
    private final ObjectProvider<R2StorageService> storageServiceProvider;

    @Transactional
    public ChatMessageDTO sendMessage(SendMessageDTO dto) {
        User sender = currentUser();
        User receiver = userRepository.findById(dto.getReceiverId())
                .orElseThrow(() -> new ResourceNotFoundException("Người nhận không tồn tại!"));

        if (sender.getId().equals(receiver.getId())) {
            throw new IllegalArgumentException("Bạn không thể tự gửi tin nhắn cho chính mình!");
        }

        // Existing matches or appointments must not bypass an admin account lock.
        if (!"ACTIVE".equalsIgnoreCase(receiver.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Không thể gửi tin nhắn vì tài khoản người nhận đã bị khóa hoặc chưa được kích hoạt!");
        }

        // 1. Kiểm tra quan hệ chặn (Block)
        if (blockedUserRepository.existsByUserIdAndBlockedUserId(sender.getId(), receiver.getId()) ||
            blockedUserRepository.existsByUserIdAndBlockedUserId(receiver.getId(), sender.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Không thể gửi tin nhắn do hai người đã chặn nhau!");
        }

        // 2. Kiểm tra quan hệ kết nối (Đã Match hoặc có Lịch hẹn xem phòng)
        boolean isMatched = matchRequestRepository.findConnectionBetweenUsers(sender.getId(), receiver.getId())
                .filter(m -> m.getStatus() == MatchRequest.MatchStatus.ACCEPTED)
                .isPresent();

        if (!isMatched) {
            boolean hasAppointment = viewingAppointmentRepository.findAllByUserId(sender.getId())
                    .stream()
                    .anyMatch(a -> a.getStatus() == ViewingAppointment.AppointmentStatus.CONFIRMED
                            && (a.getHost().getId().equals(receiver.getId()) || a.getRequester().getId().equals(receiver.getId())));
            if (!hasAppointment) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ có thể nhắn tin khi hai người đã kết nối hoặc có lịch hẹn xem phòng đã xác nhận (CONFIRMED)!");
            }
        }

        String rawContent = dto.getContent() != null ? dto.getContent().trim() : "";
        if (dto.getImageUrl() != null && !dto.getImageUrl().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "URL ảnh chat không an toàn; hãy tải ảnh riêng tư và gửi imageObjectKey!");
        }
        String imageKey = dto.getImageObjectKey();
        if (imageKey != null) imageKey = storage().requireOwnedPrivateObject(sender.getId(), "chat", imageKey);

        if (rawContent.isEmpty() && imageKey == null) {
            throw new IllegalArgumentException("Nội dung tin nhắn hoặc hình ảnh không được để trống!");
        }

        String finalContent = rawContent.isEmpty() ? "[Hình ảnh]" : rawContent;

        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .receiver(receiver)
                .content(finalContent)
                .imageUrl(imageKey)
                .isRead(false)
                .build();

        return response(chatMessageRepository.save(message), sender.getId());
    }

    @Transactional(readOnly = true)
    public List<ChatMessageDTO> getConversation(Long partnerId) {
        User current = currentUser();
        return chatMessageRepository.findConversation(current.getId(), partnerId)
                .stream()
                .map(m -> response(m, current.getId()))
                .collect(Collectors.toList());
    }

    private ChatMessageDTO response(ChatMessage message, Long viewerId) {
        ChatMessageDTO result = ChatMessageDTO.from(message, viewerId);
        User sender = message.getSender(), receiver = message.getReceiver();
        boolean participant = viewerId.equals(sender.getId()) || viewerId.equals(receiver.getId());
        if (participant && "ACTIVE".equalsIgnoreCase(sender.getStatus()) && "ACTIVE".equalsIgnoreCase(receiver.getStatus())
                && !blockedUserRepository.existsByUserIdAndBlockedUserId(sender.getId(), receiver.getId())
                && !blockedUserRepository.existsByUserIdAndBlockedUserId(receiver.getId(), sender.getId())
                && R2StorageService.isOwnedPrivateObject(sender.getId(), "chat", message.getImageUrl())) {
            R2StorageService storage = storageServiceProvider.getIfAvailable();
            if (storage != null) {
                try {
                    result.setImageUrl(storage.privateReadUrl(sender.getId(), "chat", message.getImageUrl()));
                } catch (ResponseStatusException error) {
                    if (error.getStatusCode().value() != 503) throw error;
                    // Text history remains available, without a public URL fallback.
                }
            }
        }
        return result;
    }

    private R2StorageService storage() {
        R2StorageService storage = storageServiceProvider.getIfAvailable();
        if (storage == null) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Kho ảnh riêng tư chưa được cấu hình");
        return storage;
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Bạn cần đăng nhập");
        }
        return userRepository.findByEmail(auth.getName())
                .filter(user -> "ACTIVE".equalsIgnoreCase(user.getStatus()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập không hợp lệ"));
    }
}
