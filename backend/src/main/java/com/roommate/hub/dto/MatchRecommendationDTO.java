package com.roommate.hub.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchRecommendationDTO {
    private Long userId;
    private String fullName;
    private String avatarUrl;
    private String targetDistrict;
    private Double budgetAmount;
    private String bioDescription;
    private Double totalScore;                     // Tổng điểm % tương thích
    private MatchCriteriaDetailDTO criteriaDetail; // Điểm chi tiết từng tiêu chí
}