package com.roommate.hub.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchCriteriaDetailDTO {
    private double budgetMatch;      // % phù hợp ngân sách (30%)
    private double sleepMatch;       // % phù hợp giờ giấc (25%)
    private double cleanlinessMatch; // % phù hợp vệ sinh (20%)
    private double smokingMatch;     // % phù hợp hút thuốc (15%)
    private double petMatch;         // % phù hợp thú cưng (10%)
}