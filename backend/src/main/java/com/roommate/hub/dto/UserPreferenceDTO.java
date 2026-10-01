package com.roommate.hub.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferenceDTO {
    @NotBlank(message = "Khu vực không được để trống")
    @Size(max = 100, message = "Khu vực không được vượt quá 100 ký tự")
    private String targetDistrict;

    @NotNull(message = "Ngân sách không được để trống")
    @Min(value = 500000, message = "Ngân sách tối thiểu là 500.000 VNĐ")
    private Double budgetAmount;
    @Min(0)
    private Double budgetMin;
    @Min(500000)
    private Double budgetMax;
    @jakarta.validation.constraints.Pattern(regexp = "ANY|MALE|FEMALE")
    private String targetGender;
    @jakarta.validation.constraints.Pattern(regexp = "BUDGET|SLEEP|CLEAN|SMOKING")
    private String topPriority;

    @NotNull(message = "Giờ giấc sinh hoạt không được để trống")
    @Min(value = 1, message = "Giờ giấc sinh hoạt phải từ 1 đến 3")
    @Max(value = 3, message = "Giờ giấc sinh hoạt phải từ 1 đến 3")
    private Integer sleepHabit; // 1: Ngủ sớm, 2: Bình thường, 3: Cú đêm

    @NotNull(message = "Mức độ sạch sẽ không được để trống")
    @Min(value = 1, message = "Mức độ sạch sẽ phải từ 1 đến 5")
    @Max(value = 5, message = "Mức độ sạch sẽ phải từ 1 đến 5")
    private Integer cleanlinessLevel; // 1 - 5

    @NotNull(message = "Thói quen hút thuốc không được để trống")
    private Boolean isSmoking;

    @NotNull(message = "Thói quen nuôi thú cưng không được để trống")
    private Boolean allowPets;

    private String bioDescription;
}
