package com.roommate.hub.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Giới hạn tần suất gọi các endpoint OTP (forgot-password, send-verification-email)
 * theo địa chỉ IP để ngăn chặn kẻ tấn công dùng vô số email khác nhau để
 * gây tải BCrypt/DB hoặc spam nhiều tài khoản.
 *
 * <p>Giới hạn: tối đa {@value #MAX_REQUESTS} yêu cầu trong {@value #WINDOW_SECONDS} giây.
 * Bộ đếm được reset sau mỗi cửa sổ thời gian. Cleanup tự động khi số entry vượt ngưỡng
 * hoặc theo chu kỳ.
 *
 * <p>Lưu ý: đây là in-memory rate limit, phù hợp với single-replica. Với multi-replica
 * cần dùng Redis hoặc database-backed counter.
 */
@Service
@Slf4j
public class IpRateLimitService {

    /** Số yêu cầu OTP tối đa mỗi IP trong mỗi cửa sổ thời gian. */
    static final int MAX_REQUESTS = 10;

    /** Độ dài cửa sổ tính toán rate limit (giây). */
    static final long WINDOW_SECONDS = 900; // 15 phút

    /** Xóa entry cũ khi bảng vượt ngưỡng này (tránh memory leak). */
    private static final int CLEANUP_THRESHOLD = 5000;

    private record WindowEntry(AtomicInteger count, long windowStartEpoch) {}

    private final ConcurrentHashMap<String, WindowEntry> ipCounters = new ConcurrentHashMap<>();

    /**
     * Kiểm tra và tăng bộ đếm cho {@code ip}.
     * Ném {@link ResponseStatusException} HTTP 429 nếu vượt giới hạn.
     *
     * @param ip địa chỉ IP của client (IPv4 hoặc IPv6)
     * @param endpoint tên endpoint (chỉ dùng trong log)
     */
    public void checkAndIncrement(String ip, String endpoint) {
        if (ip == null || ip.isBlank()) {
            return; // Không có IP (proxy / test) → bỏ qua
        }

        if (ipCounters.size() > CLEANUP_THRESHOLD) {
            cleanupOldEntries();
        }

        long now = Instant.now().getEpochSecond();
        WindowEntry entry = ipCounters.compute(ip, (key, existing) -> {
            if (existing == null || now - existing.windowStartEpoch() >= WINDOW_SECONDS) {
                // Cửa sổ mới hoặc chưa từng thấy IP này
                return new WindowEntry(new AtomicInteger(1), now);
            }
            existing.count().incrementAndGet();
            return existing;
        });

        if (entry.count().get() > MAX_REQUESTS) {
            log.warn("[IP_RATE_LIMIT] IP {} vượt giới hạn {} yêu cầu/{}s tại endpoint {}",
                    ip, MAX_REQUESTS, WINDOW_SECONDS, endpoint);
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                    "Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau " + WINDOW_SECONDS / 60 + " phút!");
        }
    }

    /** Xóa các entry đã hết cửa sổ thời gian để tránh memory leak. */
    void cleanupOldEntries() {
        long cutoff = Instant.now().getEpochSecond() - WINDOW_SECONDS;
        Iterator<Map.Entry<String, WindowEntry>> it = ipCounters.entrySet().iterator();
        int removed = 0;
        while (it.hasNext()) {
            if (it.next().getValue().windowStartEpoch() < cutoff) {
                it.remove();
                removed++;
            }
        }
        if (removed > 0) {
            log.debug("[IP_RATE_LIMIT] Cleaned up {} expired IP entries", removed);
        }
    }
}
