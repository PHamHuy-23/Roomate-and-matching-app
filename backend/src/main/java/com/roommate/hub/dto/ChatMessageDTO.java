package com.roommate.hub.dto;

import com.roommate.hub.entity.ChatMessage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageDTO {
    private Long id;
    private Long senderId;
    private String senderName;
    private String senderAvatar;
    private Long receiverId;
    private String receiverName;
    private String receiverAvatar;
    private String content;
    private String imageUrl;
    private Boolean isRead;
    private LocalDateTime createdAt;
    private Boolean fromMe;

    public static ChatMessageDTO from(ChatMessage message, Long currentUserId) {
        return ChatMessageDTO.builder()
                .id(message.getId())
                .senderId(message.getSender().getId())
                .senderName(message.getSender().getFullName())
                .senderAvatar(message.getSender().getAvatarUrl())
                .receiverId(message.getReceiver().getId())
                .receiverName(message.getReceiver().getFullName())
                .receiverAvatar(message.getReceiver().getAvatarUrl())
                .content(message.getContent())
                // Storage references are private. Only the authorized service may mint a read URL.
                .imageUrl(null)
                .isRead(message.getIsRead())
                .createdAt(message.getCreatedAt())
                .fromMe(message.getSender().getId().equals(currentUserId))
                .build();
    }
}
