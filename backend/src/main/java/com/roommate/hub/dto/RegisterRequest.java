package com.roommate.hub.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class RegisterRequest {
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;

    @NotBlank(message = "Họ tên không được để trống")
    private String fullName;

    @NotBlank(message = "Giới tính không được để trống")
    private String gender; // MALE hoặc FEMALE

    private String phone;

    @Past(message = "Ngày sinh phải ở trong quá khứ")
    private LocalDate birthDate;

    @Size(max = 150, message = "Tên trường không được vượt quá 150 ký tự")
    private String university;
}
