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
public class BlockedUserDTO {
    private Long id;
    private Long blockedUserId;
    private String blockedUserName;
    private String blockedUserAvatar;
    private String blockedUserEmail;
    private LocalDateTime createdAt;
}
