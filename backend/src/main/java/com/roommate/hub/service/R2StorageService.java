package com.roommate.hub.service;

import java.time.Duration;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.roommate.hub.config.R2Properties;
import com.roommate.hub.dto.CreateUploadRequest;
import com.roommate.hub.dto.UploadUrlResponse;

import lombok.RequiredArgsConstructor;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "storage.r2.enabled", havingValue = "true")
public class R2StorageService {

    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp");
    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "image/webp", ".webp");
    private static final Set<String> PURPOSES = Set.of("avatar", "room-post", "chat", "report");

    private final S3Presigner presigner;
    private final R2Properties properties;

    private String resolveDirectory(String purpose) {
        return switch (purpose) {
            case "avatar" -> "avatars";
            case "room-post" -> "room-posts";
            case "chat" -> "chat";
            case "report" -> "reports";
            default -> "misc";
        };
    }

    public UploadUrlResponse createUpload(Long userId, CreateUploadRequest request) {
        String contentType = request.contentType().trim().toLowerCase(Locale.ROOT);
        if (!ALLOWED_TYPES.contains(contentType)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP");
        }
        if (request.fileSize() > properties.getMaxUploadBytes()) {
            throw new ResponseStatusException(
                    HttpStatus.PAYLOAD_TOO_LARGE,
                    "Ảnh vượt quá dung lượng cho phép");
        }

        String purpose = request.purpose().trim().toLowerCase(Locale.ROOT);
        if (!PURPOSES.contains(purpose)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mục đích upload không hợp lệ");
        }

        String directory = resolveDirectory(purpose);
        String objectKey = "%s/%d/%s%s".formatted(
                directory,
                userId,
                UUID.randomUUID(),
                EXTENSIONS.get(contentType));
        long durationMinutes = Math.clamp(properties.getPresignDurationMinutes(), 1, 60);

        PutObjectRequest putObject = PutObjectRequest.builder()
                .bucket(properties.getBucket())
                .key(objectKey)
                .contentType(contentType)
                .contentLength(request.fileSize())
                .build();
        var presigned = presigner.presignPutObject(PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(durationMinutes))
                .putObjectRequest(putObject)
                .build());

        return new UploadUrlResponse(
                presigned.url().toString(),
                publicUrl(objectKey),
                objectKey,
                contentType,
                Duration.ofMinutes(durationMinutes).toSeconds());
    }

    public String requireOwnedObject(Long userId, String purpose, String objectKey) {
        String directory = resolveDirectory(purpose);
        String expectedPrefix = "%s/%d/".formatted(directory, userId);
        if (objectKey == null || !objectKey.startsWith(expectedPrefix) || objectKey.contains("..")) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ảnh không thuộc người dùng hiện tại");
        }
        return publicUrl(objectKey);
    }

    public String publicUrl(String objectKey) {
        return properties.getPublicUrl().replaceAll("/+$", "") + "/" + objectKey;
    }
}
