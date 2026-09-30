package com.roommate.hub.dto;

public record UploadUrlResponse(
        String uploadUrl,
        String publicUrl,
        String objectKey,
        String contentType,
        long expiresInSeconds) {
}
