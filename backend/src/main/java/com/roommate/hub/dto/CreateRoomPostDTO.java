package com.roommate.hub.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateRoomPostDTO {
    @NotNull(message = "ID tác giả không được để trống")
    private Long authorId;

    @NotBlank(message = "Tiêu đề không được để trống")
    private String title;

    @NotBlank(message = "Mô tả không được để trống")
    private String description;

    @NotNull(message = "Giá phòng không được để trống")
    @Min(value = 100000, message = "Giá tối thiểu là 100.000 VNĐ")
    private Double price;

    @NotBlank(message = "Địa chỉ không được để trống")
    private String address;

    @NotNull(message = "Số lượng người tối đa không được để trống")
    @Min(value = 1, message = "Tối thiểu là 1 người")
    private Integer maxOccupants;
}