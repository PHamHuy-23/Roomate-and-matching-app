package com.roommate.hub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CreateUploadRequest(
        @NotBlank String fileName,
        @NotBlank String contentType,
        @NotNull @Positive Long fileSize,
        @NotBlank String purpose) {
}
