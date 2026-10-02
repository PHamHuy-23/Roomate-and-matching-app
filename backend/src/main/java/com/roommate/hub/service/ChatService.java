package com.roommate.hub.service;

import com.roommate.hub.dto.ChatMessageDTO;
import com.roommate.hub.dto.SendMessageDTO;
import com.roommate.hub.entity.ChatMessage;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.ChatMessageRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.ViewingAppointment;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.ViewingAppointmentRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final BlockedUserRepository blockedUserRepository;
    private final MatchRequestRepository matchRequestRepository;
    private final ViewingAppointmentRepository viewingAppointmentRepository;

    @Value("${storage.r2.bucket:}")
    private String r2Bucket;

    @Value("${storage.r2.public-url:}")
    private String r2PublicUrl;

    void setR2Config(String r2Bucket, String r2PublicUrl) {
        this.r2Bucket = r2Bucket;
        this.r2PublicUrl = r2PublicUrl;
    }

    @Transactional
    public ChatMessageDTO sendMessage(SendMessageDTO dto) {
        User sender = currentUser();
        User receiver = userRepository.findById(dto.getReceiverId())
                .orElseThrow(() -> new ResourceNotFoundException("Người nhận không tồn tại!"));

        if (sender.getId().equals(receiver.getId())) {
            throw new RuntimeException("Bạn không thể tự gửi tin nhắn cho chính mình!");
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
        String imageUrl = dto.getImageUrl() != null && !dto.getImageUrl().isBlank() ? dto.getImageUrl().trim() : null;

        if (imageUrl != null) {
            validateImageUrl(imageUrl);
        }

        if (rawContent.isEmpty() && imageUrl == null) {
            throw new IllegalArgumentException("Nội dung tin nhắn hoặc hình ảnh không được để trống!");
        }

        String finalContent = rawContent.isEmpty() ? "[Hình ảnh]" : rawContent;

        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .receiver(receiver)
                .content(finalContent)
                .imageUrl(imageUrl)
                .isRead(false)
                .build();

        return ChatMessageDTO.from(chatMessageRepository.save(message), sender.getId());
    }

    private void validateImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return;
        }
        String trimmed = imageUrl.trim();

        // Cho phép đường dẫn tương đối nội bộ hoặc storage object key sạch
        if (trimmed.startsWith("/") || (!trimmed.contains("://") && !trimmed.contains(" "))) {
            if (trimmed.startsWith("//") || trimmed.contains("..")) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đường dẫn hình ảnh không hợp lệ!");
            }
            return;
        }

        try {
            java.net.URI uri = java.net.URI.create(trimmed);
            String scheme = uri.getScheme();
            if (scheme == null || (!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https"))) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giao thức hình ảnh không được hỗ trợ!");
            }

            String host = uri.getHost();
            if (host == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Máy chủ lưu trữ hình ảnh không hợp lệ!");
            }

            if (!isTrustedHost(host)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "URL hình ảnh không an toàn hoặc không thuộc hệ thống lưu trữ được tin cậy!");
            }
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "URL hình ảnh không đúng định dạng!");
        }
    }

    private boolean isTrustedHost(String host) {
        if (host == null) {
            return false;
        }
        String lower = host.toLowerCase(Locale.ROOT);
        if (lower.equals("localhost") || lower.equals("127.0.0.1")) {
            return true;
        }
        // Strict domain and subdomain matching (prevents evilroommatehub.com)
        if (lower.equals("roommatehub.com") || lower.endsWith(".roommatehub.com")) {
            return true;
        }
        if (lower.equals("roommatehub.vn") || lower.endsWith(".roommatehub.vn")) {
            return true;
        }
        // Specific configured app bucket/public URL, preventing arbitrary R2 attacker buckets
        if (r2PublicUrl != null && !r2PublicUrl.isBlank()) {
            try {
                java.net.URI pubUri = java.net.URI.create(r2PublicUrl);
                if (pubUri.getHost() != null && lower.equalsIgnoreCase(pubUri.getHost())) {
                    return true;
                }
            } catch (Exception ignored) {}
        }
        if (r2Bucket != null && !r2Bucket.isBlank()) {
            String appR2Host = (r2Bucket + ".r2.cloudflarestorage.com").toLowerCase(Locale.ROOT);
            if (lower.equals(appR2Host)) {
                return true;
            }
        }
        return false;
    }


    @Transactional(readOnly = true)
    public List<ChatMessageDTO> getConversation(Long partnerId) {
        User current = currentUser();
        return chatMessageRepository.findConversation(current.getId(), partnerId)
                .stream()
                .map(m -> ChatMessageDTO.from(m, current.getId()))
                .collect(Collectors.toList());
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));
    }
}
