package com.roommate.hub.dto;

import com.roommate.hub.entity.MatchRequest;
import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchRequestResponseDTO {
    private Long requestId;
    private Long partnerId;
    private String partnerName;
    private String partnerAvatar;
    private Double matchScore;
    private String status;
    private LocalDateTime createdAt;

    // Các trường chỉ hiển thị khi ACCEPTED (QĐ 2)
    private String contactPhone;
    private String contactEmail;
}