package com.roommate.hub.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class LoginAttemptServiceTest {

    private LoginAttemptService loginAttemptService;

    @BeforeEach
    void setUp() {
        loginAttemptService = new LoginAttemptService();
    }

    @Test
    @DisplayName("User is not blocked initially")
    void testNotBlockedInitially() {
        assertFalse(loginAttemptService.isBlocked("test@example.com"));
    }

    @Test
    @DisplayName("User is blocked after 5 failed attempts")
    void testBlockedAfterFiveFailedAttempts() {
        String email = "victim@example.com";
        for (int i = 0; i < 4; i++) {
            loginAttemptService.loginFailed(email);
            assertFalse(loginAttemptService.isBlocked(email), "Should not be blocked after " + (i + 1) + " attempts");
        }

        // 5th attempt
        loginAttemptService.loginFailed(email);
        assertTrue(loginAttemptService.isBlocked(email), "Should be blocked after 5 failed attempts");
    }

    @Test
    @DisplayName("Successful login resets failed attempts")
    void testSuccessfulLoginResetsAttempts() {
        String email = "user@example.com";
        for (int i = 0; i < 4; i++) {
            loginAttemptService.loginFailed(email);
        }

        // Successful login
        loginAttemptService.loginSucceeded(email);
        assertFalse(loginAttemptService.isBlocked(email));

        // Another failed attempt should start count at 1, not 5
        loginAttemptService.loginFailed(email);
        assertFalse(loginAttemptService.isBlocked(email));
    }

    @Test
    @DisplayName("Email normalization works across cases and spaces")
    void testEmailNormalization() {
        String email = "  user@EXAMPLE.com ";
        for (int i = 0; i < 5; i++) {
            loginAttemptService.loginFailed(email);
        }

        assertTrue(loginAttemptService.isBlocked("user@example.com"));
    }
}
