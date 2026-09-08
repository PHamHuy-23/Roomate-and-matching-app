package com.roommate.hub.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomPostDTO {
    private Long id;
    private String title;
    private String description;
    private Double price;
    private String address;
    private Integer maxOccupants;
    private String imageUrl;
    private String authorName;
    private Long authorId;
}