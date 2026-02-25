package com.service;

public interface EmailService {
    void sendPasswordResetOtpEmail(String toEmail, String userName, String otpCode, int expiryMinutes);
    void sendNotificationEmail(String toEmail, String userName, String subject, String headline, String message);
}
