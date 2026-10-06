package com.roommate.hub.dto;

import com.roommate.hub.entity.RoomPost;
import lombok.Builder;
import lombok.Value;
import java.time.LocalDateTime;

@Value @Builder
public class AdminPostResponseDTO {
    Long id; Long version; Long authorId; String authorName; String title; String description; Double price;
    String address; Integer maxOccupants; String imageUrl; String status; LocalDateTime createdAt;
    boolean publiclyVisible;

    public static AdminPostResponseDTO from(RoomPost p) {
        // Match the public feed: an approved/available post owned by an active account.
        boolean visible = "ACTIVE".equals(p.getAuthor().getStatus())
                && (p.getStatus() == RoomPost.PostStatus.APPROVED
                || p.getStatus() == RoomPost.PostStatus.AVAILABLE);
        return AdminPostResponseDTO.builder()
                .id(p.getId()).version(p.getVersion()).authorId(p.getAuthor().getId()).authorName(p.getAuthor().getFullName())
                .title(p.getTitle()).description(p.getDescription()).price(p.getPrice())
                .address(p.getAddress()).maxOccupants(p.getMaxOccupants()).imageUrl(p.getImageUrl())
                .status(p.getStatus().name()).createdAt(p.getCreatedAt()).publiclyVisible(visible).build();
    }
}
