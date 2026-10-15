package com.roommate.hub.dto;

import com.roommate.hub.validation.NewPassword;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ChangePasswordRequest {
    @NotBlank(message = "Mật khẩu hiện tại không được để trống")
    private String oldPassword;

    @NewPassword
    private String newPassword;
}
