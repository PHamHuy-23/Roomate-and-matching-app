package com.roommate.hub.dto;

import com.roommate.hub.entity.User;
import lombok.Builder;
import lombok.Value;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Value
@Builder
public class UserResponseDTO {
    Long id; String email; String fullName; String gender; String phone; String avatarUrl;
    LocalDate birthDate; String university; String role; String status;
    LocalDateTime createdAt;

    public static UserResponseDTO from(User user) {
        return UserResponseDTO.builder().id(user.getId()).email(user.getEmail()).fullName(user.getFullName())
                .gender(user.getGender()).phone(user.getPhone()).avatarUrl(user.getAvatarUrl())
                .birthDate(user.getBirthDate()).university(user.getUniversity())
                .role(user.getRole().name()).status(user.getStatus()).createdAt(user.getCreatedAt()).build();
    }
}
