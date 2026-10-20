package com.roommate.hub.service;

import java.time.Instant;

public interface EmailService {
    void sendPasswordResetOtp(String toEmail, String otp);
    void sendVerificationOtp(String toEmail, String otp);
    void simulateDeliveryDelay();
    void sendAppointmentReminder(String toEmail, String recipientName, String partnerName, String roomTitle, Instant appointmentTime, String address);
}
