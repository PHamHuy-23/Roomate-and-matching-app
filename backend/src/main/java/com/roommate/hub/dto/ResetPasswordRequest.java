package com.roommate.hub.dto;

import com.roommate.hub.validation.NewPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ResetPasswordRequest {
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    @Size(max = 100, message = "Email không được vượt quá 100 ký tự")
    private String email;

    @NotBlank(message = "Mã xác nhận không được để trống")
    @Pattern(regexp = "[0-9]{6}", message = "Mã xác nhận phải gồm đúng 6 chữ số")
    private String code;

    @NewPassword
    private String newPassword;
}
