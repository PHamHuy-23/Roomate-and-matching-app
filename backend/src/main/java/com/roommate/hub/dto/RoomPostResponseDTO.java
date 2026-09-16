package com.roommate.hub.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomPostResponseDTO {
    private Long id;
    private Long authorId;
    private String authorName;
    private String authorAvatar;
    private String title;
    private String description;
    private Double price;
    private String address;
    private String district;
    private Double deposit;
    private Double electricityWaterCost;
    private Double area;
    private Integer maxOccupants;
    private Integer currentOccupants;
    private String amenities;
    private LocalDateTime createdAt;
}