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

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;

    @Transactional
    public ChatMessageDTO sendMessage(SendMessageDTO dto) {
        User sender = currentUser();
        User receiver = userRepository.findById(dto.getReceiverId())
                .orElseThrow(() -> new ResourceNotFoundException("Người nhận không tồn tại!"));

        if (sender.getId().equals(receiver.getId())) {
            throw new RuntimeException("Bạn không thể tự gửi tin nhắn cho chính mình!");
        }

        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .receiver(receiver)
                .content(dto.getContent().trim())
                .imageUrl(dto.getImageUrl())
                .isRead(false)
                .build();

        return ChatMessageDTO.from(chatMessageRepository.save(message), sender.getId());
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
