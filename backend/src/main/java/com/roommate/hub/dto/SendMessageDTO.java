package com.roommate.hub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SendMessageDTO {

    @NotNull(message = "Người nhận không được để trống")
    private Long receiverId;

    @NotBlank(message = "Nội dung tin nhắn không được để trống")
    private String content;

    private String imageUrl;
}
