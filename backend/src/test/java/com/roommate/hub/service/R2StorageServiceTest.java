package com.roommate.hub.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.roommate.hub.config.R2Properties;
import com.roommate.hub.dto.CreateUploadRequest;
import com.roommate.hub.dto.UploadUrlResponse;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

class R2StorageServiceTest {

    private static final String FILE = "12345678-abcd-1234-abcd-123456789abc.png";
    private R2Properties properties;
    private S3Presigner presigner;
    private R2StorageService storage;

    @BeforeEach
    void setUp() {
        properties = new R2Properties();
        properties.setBucket("test-public-bucket");
        properties.setPrivateBucket("test-private-bucket");
        properties.setPublicUrl("https://public.example.test///");
        // Dummy credentials: signing is local only; no request is sent to any service.
        presigner = S3Presigner.builder()
                .endpointOverride(URI.create("https://r2.example.test"))
                .region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create("test-access-key", "test-secret-not-valid")))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .build();
        storage = new R2StorageService(presigner, properties);
    }

    @AfterEach
    void closePresigner() {
        presigner.close();
    }

    @ParameterizedTest
    @CsvSource({
            "chat,chat,image/jpeg,jpg", "chat,chat,image/png,png", "chat,chat,image/webp,webp",
            "report,reports,image/jpeg,jpg", "report,reports,image/png,png", "report,reports,image/webp,webp"
    })
    void privateUploadUsesOnlyPrivateBucketAndNeverReturnsPublicUrl(
            String purpose, String directory, String contentType, String extension) {
        UploadUrlResponse response = storage.createUpload(42L,
                new CreateUploadRequest("ignored-client-name.png", contentType, 123L, purpose));

        assertThat(response.publicUrl()).isNull();
        assertThat(response.objectKey()).matches(directory
                + "/42/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\." + extension);
        assertThat(response.contentType()).isEqualTo(contentType);
        assertThat(response.expiresInSeconds()).isEqualTo(600);
        assertThat(URI.create(response.uploadUrl()).getPath())
                .isEqualTo("/test-private-bucket/" + response.objectKey());
        assertThat(query(response.uploadUrl())).containsEntry("X-Amz-Expires", "600");
        assertThat(query(response.uploadUrl()).get("X-Amz-SignedHeaders"))
                .contains("cache-control", "content-length", "content-type");
        assertThat(storage.requireOwnedPrivateObject(42L, purpose, response.objectKey()))
                .isEqualTo(response.objectKey());
    }

    @ParameterizedTest
    @CsvSource({"avatar,avatars", "room-post,room-posts"})
    void publicUploadStillReturnsPublicUrlWithoutPrivateConfiguration(String purpose, String directory) {
        properties.setPrivateBucket(null);
        UploadUrlResponse response = storage.createUpload(42L,
                new CreateUploadRequest("photo.png", " IMAGE/PNG ", 123L, " " + purpose + " "));

        assertThat(response.objectKey()).startsWith(directory + "/42/");
        assertThat(response.publicUrl()).isEqualTo("https://public.example.test/" + response.objectKey());
        assertThat(response.contentType()).isEqualTo("image/png");
        assertThat(URI.create(response.uploadUrl()).getPath())
                .isEqualTo("/test-public-bucket/" + response.objectKey());
        assertThat(query(response.uploadUrl()).get("X-Amz-SignedHeaders"))
                .doesNotContain("cache-control");
        assertThat(storage.requireOwnedObject(42L, purpose, response.objectKey()))
                .isEqualTo(response.publicUrl());
    }

    @ParameterizedTest
    @CsvSource({"chat,chat", "report,reports"})
    void privateReadPresignsOnlyPrivateBucketWithNoStore(String purpose, String directory) {
        String key = directory + "/42/" + FILE;
        String url = storage.privateReadUrl(42L, purpose, key);

        assertThat(URI.create(url).getPath()).isEqualTo("/test-private-bucket/" + key);
        assertThat(query(url)).containsEntry("X-Amz-Expires", "120")
                .containsEntry("response-cache-control", "private, no-store")
                .containsKey("X-Amz-Signature");
        assertThat(url).doesNotContain("public.example.test", "test-public-bucket");
    }

    @ParameterizedTest
    @CsvSource({"-10,60", "0,60", "1,60", "2,120", "5,300", "6,300", "500,300"})
    void privateReadExpiryIsBoundedToOneToFiveMinutes(long configuredMinutes, String expectedSeconds) {
        properties.setPrivateReadDurationMinutes(configuredMinutes);
        assertThat(query(storage.privateReadUrl(42L, "chat", "chat/42/" + FILE)))
                .containsEntry("X-Amz-Expires", expectedSeconds);
    }

    @ParameterizedTest
    @MethodSource("invalidPrivateBuckets")
    void privateOperationsFailClosedWithoutSeparatePrivateBucket(String invalidBucket) {
        properties.setPrivateBucket(invalidBucket);
        assertStatus(HttpStatus.SERVICE_UNAVAILABLE, () -> storage.createUpload(42L,
                new CreateUploadRequest("photo.png", "image/png", 123L, "chat")));
        assertStatus(HttpStatus.SERVICE_UNAVAILABLE,
                () -> storage.requireOwnedPrivateObject(42L, "report", "reports/42/" + FILE));
        assertStatus(HttpStatus.SERVICE_UNAVAILABLE,
                () -> storage.privateReadUrl(42L, "chat", "chat/42/" + FILE));
        // A broken private config must not disable existing public uploads.
        assertThat(storage.createUpload(42L,
                new CreateUploadRequest("photo.png", "image/png", 123L, "avatar")).publicUrl())
                .startsWith("https://public.example.test/avatars/42/");
    }

    static Stream<Arguments> invalidPrivateBuckets() {
        return Stream.of(null, "", " ", "YOUR_PRIVATE_BUCKET", "REPLACE_WITH_PRIVATE_BUCKET",
                "test-public-bucket", "Test-Bucket", "invalid/bucket", "x", " test-private-bucket ")
                .map(Arguments::of);
    }

    @ParameterizedTest
    @MethodSource("invalidPrivateKeys")
    void privateKeyValidationRejectsUrlsTraversalNoncanonicalWrongPurposeAndWrongOwner(String key) {
        assertThat(R2StorageService.isOwnedPrivateObject(42L, "chat", key)).isFalse();
        assertStatus(HttpStatus.FORBIDDEN, () -> storage.requireOwnedPrivateObject(42L, "chat", key));
        assertStatus(HttpStatus.FORBIDDEN, () -> storage.privateReadUrl(42L, "chat", key));
    }

    static Stream<Arguments> invalidPrivateKeys() {
        return Stream.of(null, "", "chat/43/" + FILE, "reports/42/" + FILE, "avatars/42/" + FILE,
                "room-posts/42/" + FILE, "chat/0/" + FILE, "chat/042/" + FILE, "chat/-42/" + FILE,
                "chat/42/../" + FILE, "chat/42/%2e%2e/" + FILE, "chat/42/" + FILE + "?token=secret",
                "chat/42/" + FILE + "#fragment", "https://public.example.test/chat/42/" + FILE,
                "/chat/42/" + FILE, "chat//42/" + FILE, "chat\\42\\" + FILE, "chat/42/nested/" + FILE,
                "chat/42/not-a-uuid.png", "chat/42/" + FILE.toUpperCase(), "chat/42/" + FILE + "/extra",
                " chat/42/" + FILE, "chat/42/" + FILE + " ", "chat/42/12345678-abcd-1234-abcd-123456789abc.svg")
                .map(Arguments::of);
    }

    @ParameterizedTest
    @ValueSource(strings = {"avatar", "room-post", "misc", "", "unknown"})
    void nonprivatePurposeCannotBeUsedForPrivateOperations(String purpose) {
        assertThat(R2StorageService.isOwnedPrivateObject(42L, purpose, "chat/42/" + FILE)).isFalse();
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> storage.requireOwnedPrivateObject(42L, purpose, "chat/42/" + FILE));
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> storage.privateReadUrl(42L, purpose, "chat/42/" + FILE));
    }

    @ParameterizedTest
    @ValueSource(strings = {"chat", "report", "misc", ""})
    void publicOwnershipHelperCannotPublishPrivateImages(String purpose) {
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> storage.requireOwnedObject(42L, purpose, "chat/42/" + FILE));
    }

    @ParameterizedTest
    @ValueSource(strings = {"chat", "reports"})
    void publicUrlHelperCannotPublishPrivateImages(String directory) {
        assertStatus(HttpStatus.FORBIDDEN, () -> storage.publicUrl(directory + "/42/" + FILE));
    }

    @Test
    void publicOwnershipHelperAlsoRejectsUnownedAndNoncanonicalKeys() {
        assertStatus(HttpStatus.FORBIDDEN,
                () -> storage.requireOwnedObject(42L, "avatar", "avatars/43/" + FILE));
        assertStatus(HttpStatus.FORBIDDEN,
                () -> storage.requireOwnedObject(42L, "avatar", "avatars/42/not-a-uuid.png"));
        assertStatus(HttpStatus.FORBIDDEN,
                () -> storage.requireOwnedObject(42L, "room-post", "avatars/42/" + FILE));
        assertStatus(HttpStatus.FORBIDDEN,
                () -> storage.publicUrl("room-posts/42/../" + FILE));
    }

    @Test
    void pureValidationDoesNotDependOnConfiguredStorageAndAcceptsOnlyOwnedCanonicalKeys() {
        properties.setPrivateBucket(null);
        assertThat(R2StorageService.isOwnedPrivateObject(42L, "chat", "chat/42/" + FILE)).isTrue();
        assertThat(R2StorageService.isOwnedPrivateObject(42L, "report", "reports/42/" + FILE)).isTrue();
        assertThat(R2StorageService.isOwnedPrivateObject(null, "chat", "chat/42/" + FILE)).isFalse();
        assertThat(R2StorageService.isOwnedPrivateObject(0L, "chat", "chat/42/" + FILE)).isFalse();
        assertThat(R2StorageService.isOwnedPrivateObject(42L, null, "chat/42/" + FILE)).isFalse();
    }

    @Test
    void uploadInputValidationRejectsUnsafeTypesMissingDataAndOversizedImages() {
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(null,
                new CreateUploadRequest("image.png", "image/png", 1L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(0L,
                new CreateUploadRequest("image.png", "image/png", 1L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L, null));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", null, 1L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.svg", "image/svg+xml", 1L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", null, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", 0L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", -1L, "chat")));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", 1L, null)));
        assertStatus(HttpStatus.BAD_REQUEST, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", 1L, "unknown")));
        assertStatus(HttpStatus.PAYLOAD_TOO_LARGE, () -> storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", properties.getMaxUploadBytes() + 1, "chat")));
    }

    @ParameterizedTest
    @CsvSource({"0,60", "1,60", "10,600", "100,3600"})
    void uploadExpiryRemainsBoundedToOneToSixtyMinutes(long minutes, String seconds) {
        properties.setPresignDurationMinutes(minutes);
        UploadUrlResponse response = storage.createUpload(42L,
                new CreateUploadRequest("image.png", "image/png", 1L, "chat"));
        assertThat(query(response.uploadUrl())).containsEntry("X-Amz-Expires", seconds);
        assertThat(response.expiresInSeconds()).isEqualTo(Long.parseLong(seconds));
    }

    private static Map<String, String> query(String url) {
        return Arrays.stream(URI.create(url).getRawQuery().split("&"))
                .map(part -> part.split("=", 2))
                .collect(Collectors.toMap(pair -> URLDecoder.decode(pair[0], StandardCharsets.UTF_8),
                        pair -> URLDecoder.decode(pair[1], StandardCharsets.UTF_8)));
    }

    private static void assertStatus(HttpStatus status, Runnable action) {
        assertThatThrownBy(action::run).isInstanceOf(ResponseStatusException.class)
                .satisfies(error -> assertThat(((ResponseStatusException) error).getStatusCode()).isEqualTo(status));
    }
}
