package com.roommate.hub.service;

import java.time.Duration;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.roommate.hub.config.R2Properties;
import com.roommate.hub.dto.CreateUploadRequest;
import com.roommate.hub.dto.UploadUrlResponse;

import lombok.RequiredArgsConstructor;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
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
    private static final Set<String> PUBLIC_PURPOSES = Set.of("avatar", "room-post");
    private static final Set<String> PRIVATE_PURPOSES = Set.of("chat", "report");
    private static final Pattern OBJECT_KEY = Pattern.compile(
            "(avatars|room-posts|chat|reports)/([1-9][0-9]*)/"
                    + "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(jpg|png|webp)");

    private final S3Presigner presigner;
    private final R2Properties properties;

    private static String resolveDirectory(String purpose) {
        return switch (purpose) {
            case "avatar" -> "avatars";
            case "room-post" -> "room-posts";
            case "chat" -> "chat";
            case "report" -> "reports";
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Mục đích upload không hợp lệ");
        };
    }

    public UploadUrlResponse createUpload(Long userId, CreateUploadRequest request) {
        if (userId == null || userId <= 0 || request == null || request.contentType() == null
                || request.fileSize() == null || request.fileSize() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thông tin upload không hợp lệ");
        }
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

        String purpose = requirePurpose(request.purpose(), PURPOSES);
        boolean privateUpload = PRIVATE_PURPOSES.contains(purpose);
        String bucket = privateUpload ? requirePrivateBucket() : properties.getBucket();

        String directory = resolveDirectory(purpose);
        String objectKey = "%s/%d/%s%s".formatted(
                directory,
                userId,
                UUID.randomUUID(),
                EXTENSIONS.get(contentType));
        long durationMinutes = Math.clamp(properties.getPresignDurationMinutes(), 1, 60);

        PutObjectRequest putObject = PutObjectRequest.builder()
                .bucket(bucket)
                .key(objectKey)
                .contentType(contentType)
                .contentLength(request.fileSize())
                .cacheControl(privateUpload ? "private, no-store" : null)
                .build();
        var presigned = presigner.presignPutObject(PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(durationMinutes))
                .putObjectRequest(putObject)
                .build());

        return new UploadUrlResponse(
                presigned.url().toString(),
                privateUpload ? null : publicUrl(objectKey),
                objectKey,
                contentType,
                Duration.ofMinutes(durationMinutes).toSeconds());
    }

    public String requireOwnedObject(Long userId, String purpose, String objectKey) {
        String publicPurpose = requirePurpose(purpose, PUBLIC_PURPOSES);
        if (!isOwnedObject(userId, publicPurpose, objectKey)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ảnh không thuộc người dùng hiện tại");
        }
        return publicUrl(objectKey);
    }

    public String publicUrl(String objectKey) {
        if (objectKey == null || !OBJECT_KEY.matcher(objectKey).matches()
                || !(objectKey.startsWith("avatars/") || objectKey.startsWith("room-posts/"))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ảnh công khai không hợp lệ");
        }
        return properties.getPublicUrl().replaceAll("/+$", "") + "/" + objectKey;
    }

    public String requireOwnedPrivateObject(Long userId, String purpose, String objectKey) {
        String privatePurpose = requirePurpose(purpose, PRIVATE_PURPOSES);
        if (!isOwnedPrivateObject(userId, privatePurpose, objectKey)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ảnh không thuộc người dùng hiện tại");
        }
        requirePrivateBucket();
        return objectKey;
    }

    // Callers must authorize access to the message/report before requesting a link.
    public String privateReadUrl(Long ownerId, String purpose, String objectKey) {
        String ownedKey = requireOwnedPrivateObject(ownerId, purpose, objectKey);
        long durationMinutes = Math.clamp(properties.getPrivateReadDurationMinutes(), 1, 5);
        GetObjectRequest getObject = GetObjectRequest.builder()
                .bucket(requirePrivateBucket())
                .key(ownedKey)
                .responseCacheControl("private, no-store")
                .build();
        return presigner.presignGetObject(GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(durationMinutes))
                .getObjectRequest(getObject)
                .build()).url().toString();
    }

    // Pure validation also lets DTO mappers redact legacy public URLs without an R2 connection.
    public static boolean isOwnedPrivateObject(Long ownerId, String purpose, String objectKey) {
        return purpose != null && PRIVATE_PURPOSES.contains(purpose)
                && isOwnedObject(ownerId, purpose, objectKey);
    }

    private static boolean isOwnedObject(Long ownerId, String purpose, String objectKey) {
        return ownerId != null && ownerId > 0 && objectKey != null
                && OBJECT_KEY.matcher(objectKey).matches()
                && objectKey.startsWith("%s/%d/".formatted(resolveDirectory(purpose), ownerId));
    }

    private static String requirePurpose(String purpose, Set<String> allowed) {
        String normalized = purpose == null ? "" : purpose.trim().toLowerCase(Locale.ROOT);
        if (!allowed.contains(normalized)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mục đích upload không hợp lệ");
        }
        return normalized;
    }

    private String requirePrivateBucket() {
        String bucket = properties.getPrivateBucket();
        String publicBucket = properties.getBucket();
        if (bucket == null || bucket.isBlank() || bucket.startsWith("YOUR_")
                || bucket.startsWith("REPLACE_")
                || !bucket.matches("[a-z0-9][a-z0-9-]{1,61}[a-z0-9]")
                || (publicBucket != null && bucket.equals(publicBucket.trim()))) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "R2_PRIVATE_BUCKET_NAME phải là bucket riêng tư riêng biệt đã được cấu hình");
        }
        return bucket;
    }
}
