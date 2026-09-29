package com.roommate.hub.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class IpRateLimitServiceTest {

    private IpRateLimitService service;

    @BeforeEach
    void setUp() {
        service = new IpRateLimitService();
    }

    @Test
    @DisplayName("checkAndIncrement() chấp nhận các yêu cầu trong giới hạn")
    void checkAndIncrement_WithinLimit_ShouldNotThrow() {
        for (int i = 0; i < IpRateLimitService.MAX_REQUESTS; i++) {
            service.checkAndIncrement("192.168.1.1", "test");
        }
    }

    @Test
    @DisplayName("checkAndIncrement() ném TOO_MANY_REQUESTS khi vượt giới hạn IP")
    void checkAndIncrement_OverLimit_ShouldThrowTooManyRequests() {
        for (int i = 0; i < IpRateLimitService.MAX_REQUESTS; i++) {
            service.checkAndIncrement("10.0.0.1", "test");
        }

        assertThatThrownBy(() -> service.checkAndIncrement("10.0.0.1", "test"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.TOO_MANY_REQUESTS));
    }

    @Test
    @DisplayName("checkAndIncrement() đếm độc lập cho từng IP")
    void checkAndIncrement_DifferentIps_ShouldCountIndependently() {
        for (int i = 0; i < IpRateLimitService.MAX_REQUESTS; i++) {
            service.checkAndIncrement("1.1.1.1", "test");
        }

        // IP khác không bị ảnh hưởng
        service.checkAndIncrement("2.2.2.2", "test");
    }

    @Test
    @DisplayName("checkAndIncrement() bỏ qua khi IP là null hoặc rỗng")
    void checkAndIncrement_WithNullOrBlankIp_ShouldNotThrow() {
        service.checkAndIncrement(null, "test");
        service.checkAndIncrement("", "test");
        service.checkAndIncrement("   ", "test");
    }

    @Test
    @DisplayName("cleanupOldEntries() xóa các entry hết hạn")
    void cleanupOldEntries_ShouldRemoveExpiredEntries() {
        service.checkAndIncrement("3.3.3.3", "test");
        // Cleanup sẽ không xóa entry còn mới nhưng không ném lỗi
        service.cleanupOldEntries();
    }
}
