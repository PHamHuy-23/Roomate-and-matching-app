package com.roommate.hub.dto;

import jakarta.validation.constraints.NotBlank;

public record ConfirmAvatarRequest(@NotBlank String objectKey) {
}
