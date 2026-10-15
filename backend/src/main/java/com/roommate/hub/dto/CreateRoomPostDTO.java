package com.roommate.hub.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.groups.Default;
import lombok.Data;

@Data
public class CreateRoomPostDTO {
    // Updates may omit fields, but every supplied value must satisfy default constraints.
    public interface OnCreate extends Default {}

    @NotBlank(groups = OnCreate.class, message = "Tiêu đề không được để trống")
    @Pattern(regexp = "(?s).*\\S.*", message = "Tiêu đề không được để trống")
    @Size(max = 200, message = "Tiêu đề không được vượt quá 200 ký tự")
    private String title;

    @NotBlank(groups = OnCreate.class, message = "Mô tả không được để trống")
    @Pattern(regexp = "(?s).*\\S.*", message = "Mô tả không được để trống")
    private String description;

    @NotNull(groups = OnCreate.class, message = "Giá phòng không được để trống")
    @Min(value = 100000, message = "Giá tối thiểu là 100.000 VNĐ")
    private Double price;

    @NotBlank(groups = OnCreate.class, message = "Địa chỉ không được để trống")
    @Pattern(regexp = "(?s).*\\S.*", message = "Địa chỉ không được để trống")
    @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự")
    private String address;

    @Pattern(regexp = "(?s).*\\S.*", message = "Khu vực không được để trống khi cung cấp")
    @Size(max = 100, message = "Khu vực không được vượt quá 100 ký tự")
    private String district;

    @Min(value = 0, message = "Tiền cọc không được âm")
    private Double deposit;

    @Min(value = 0, message = "Chi phí điện nước không được âm")
    private Double electricityWaterCost;

    @Min(value = 0, message = "Diện tích không được âm")
    private Double area;

    @NotNull(groups = OnCreate.class, message = "Số lượng người tối đa không được để trống")
    @Min(value = 1, message = "Tối thiểu là 1 người")
    private Integer maxOccupants;

    @Min(value = 0, message = "Số người hiện tại không được âm")
    private Integer currentOccupants;

    @Size(max = 500, message = "Tiện ích không được vượt quá 500 ký tự")
    private String amenities;

    private String imageObjectKey;
}
