package com.roommate.hub.dto;

import com.roommate.hub.validation.NewPassword;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class RegisterRequest {
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    @Size(max = 100, message = "Email không được vượt quá 100 ký tự")
    private String email;

    @NewPassword
    private String password;

    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên không được vượt quá 100 ký tự")
    private String fullName;

    @NotBlank(message = "Giới tính không được để trống")
    @Pattern(regexp = "(?i:MALE|FEMALE|OTHER)", message = "Giới tính phải là MALE, FEMALE hoặc OTHER")
    private String gender;

    @Size(max = 20, message = "Số điện thoại không được vượt quá 20 ký tự")
    private String phone;

    @NotNull(message = "Ngày sinh không được để trống")
    @Past(message = "Ngày sinh phải ở trong quá khứ")
    private LocalDate birthDate;

    @NotBlank(message = "Trường đại học không được để trống")
    @Size(max = 150, message = "Tên trường không được vượt quá 150 ký tự")
    private String university;

    @AssertTrue(message = "Người dùng phải đủ 18 tuổi")
    public boolean isAdult() {
        return birthDate == null || !birthDate.isAfter(LocalDate.now().minusYears(18));
    }
}
