package com.service;

public interface EmailService {
    void sendPasswordResetOtpEmail(String toEmail, String userName, String otpCode, int expiryMinutes);
}
