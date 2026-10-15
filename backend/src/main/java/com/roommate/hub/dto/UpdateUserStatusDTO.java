package com.roommate.hub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class UpdateUserStatusDTO {
    @NotBlank(message = "Trạng thái tài khoản không được để trống")
    @Pattern(regexp = "ACTIVE|LOCKED", message = "Trạng thái tài khoản phải là ACTIVE hoặc LOCKED")
    private String status;
}
