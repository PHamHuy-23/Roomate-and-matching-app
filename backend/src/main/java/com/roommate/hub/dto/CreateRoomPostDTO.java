package com.roommate.hub.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateRoomPostDTO {
    @NotBlank(message = "Tiêu đề không được để trống")
    private String title;

    @NotBlank(message = "Mô tả không được để trống")
    private String description;

    @NotNull(message = "Giá phòng không được để trống")
    @Min(value = 100000, message = "Giá tối thiểu là 100.000 VNĐ")
    private Double price;

    @NotBlank(message = "Địa chỉ không được để trống")
    private String address;

    private String district;

    @Min(value = 0, message = "Tiền cọc không được âm")
    private Double deposit;

    @Min(value = 0, message = "Chi phí điện nước không được âm")
    private Double electricityWaterCost;

    @Min(value = 0, message = "Diện tích không được âm")
    private Double area;

    @NotNull(message = "Số lượng người tối đa không được để trống")
    @Min(value = 1, message = "Tối thiểu là 1 người")
    private Integer maxOccupants;

    @Min(value = 0, message = "Số người hiện tại không được âm")
    private Integer currentOccupants;

    private String amenities;

    private String imageObjectKey;
}
