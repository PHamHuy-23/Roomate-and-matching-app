package com.roommate.hub.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferenceDTO {
    @NotBlank(message = "Khu vực không được để trống")
    private String targetDistrict;

    @NotNull(message = "Ngân sách không được để trống")
    @Min(value = 500000, message = "Ngân sách tối thiểu là 500.000 VNĐ")
    private Double budgetAmount;

    @NotNull(message = "Giờ giấc sinh hoạt không được để trống")
    private Integer sleepHabit; // 1: Ngủ sớm, 2: Bình thường, 3: Cú đêm

    @NotNull(message = "Mức độ sạch sẽ không được để trống")
    private Integer cleanlinessLevel; // 1 - 5

    @NotNull(message = "Thói quen hút thuốc không được để trống")
    private Boolean isSmoking;

    @NotNull(message = "Thói quen nuôi thú cưng không được để trống")
    private Boolean allowPets;

    private String bioDescription;
}