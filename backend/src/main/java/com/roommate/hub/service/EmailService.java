package com.roommate.hub.service;

public interface EmailService {
    void sendPasswordResetOtp(String toEmail, String otp);
    void sendVerificationOtp(String toEmail, String otp);
    void simulateDeliveryDelay();
}
