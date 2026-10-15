package com.roommate.hub.service;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class LoginAttemptService {

    public static final int MAX_FAILED_ATTEMPTS = 5;
    public static final long LOCK_DURATION_SECONDS = 15 * 60; // 15 phút khóa nếu dò sai quá 5 lần

    private static class Attempt {
        int count;
        Instant firstFailedTime;
        Instant lockedUntil;

        Attempt(Instant now) {
            this.count = 1;
            this.firstFailedTime = now;
        }
    }

    private final Map<String, Attempt> attempts = new ConcurrentHashMap<>();

    public boolean isBlocked(String key) {
        if (key == null || key.isBlank()) return false;
        String normalizedKey = key.trim().toLowerCase();
        Attempt attempt = attempts.get(normalizedKey);
        if (attempt == null) return false;

        Instant now = Instant.now();
        if (attempt.lockedUntil != null) {
            if (now.isBefore(attempt.lockedUntil)) {
                return true;
            } else {
                attempts.remove(normalizedKey);
                return false;
            }
        }

        if (now.isAfter(attempt.firstFailedTime.plusSeconds(LOCK_DURATION_SECONDS))) {
            attempts.remove(normalizedKey);
            return false;
        }

        return attempt.count >= MAX_FAILED_ATTEMPTS;
    }

    public void loginFailed(String key) {
        if (key == null || key.isBlank()) return;
        String normalizedKey = key.trim().toLowerCase();
        Instant now = Instant.now();
        attempts.compute(normalizedKey, (k, existing) -> {
            if (existing == null || now.isAfter(existing.firstFailedTime.plusSeconds(LOCK_DURATION_SECONDS))) {
                return new Attempt(now);
            }
            existing.count++;
            if (existing.count >= MAX_FAILED_ATTEMPTS) {
                existing.lockedUntil = now.plusSeconds(LOCK_DURATION_SECONDS);
            }
            return existing;
        });
    }

    public void loginSucceeded(String key) {
        if (key == null || key.isBlank()) return;
        attempts.remove(key.trim().toLowerCase());
    }

    public void reset() {
        attempts.clear();
    }
}
