package com.serviceImpl;

import com.service.EmailService;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class SmtpEmailServiceImpl implements EmailService {

    private static final Logger LOGGER = LoggerFactory.getLogger(SmtpEmailServiceImpl.class);
    private final JavaMailSender mailSender;
    private final String fromEmail;

    public SmtpEmailServiceImpl(JavaMailSender mailSender,
                                @Value("${app.mail.from}") String fromEmail) {
        this.mailSender = mailSender;
        this.fromEmail = fromEmail;
    }

    @Override
    public void sendPasswordResetOtpEmail(String toEmail, String userName, String otpCode, int expiryMinutes) {
        String safeName = (userName == null || userName.trim().isEmpty()) ? "User" : userName.trim();
        String subject = "Your StayBooking password reset OTP";
        String htmlBody = buildPasswordResetHtml(safeName, otpCode, expiryMinutes);
        sendHtmlEmail(toEmail, subject, htmlBody, "password reset OTP");
    }

    @Override
    public void sendNotificationEmail(String toEmail, String userName, String subject, String headline, String message) {
        String safeName = (userName == null || userName.trim().isEmpty()) ? "User" : userName.trim();
        String htmlBody = buildNotificationHtml(safeName, headline, message);
        sendHtmlEmail(toEmail, subject, htmlBody, "notification");
    }

    private void sendHtmlEmail(String toEmail, String subject, String htmlBody, String emailType) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "UTF-8");
            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlBody, true);
            mailSender.send(mimeMessage);
            LOGGER.info("{} email sent successfully to {}", emailType, toEmail);
        } catch (MessagingException | MailException ex) {
            LOGGER.error("Failed to send {} email to {}. Reason: {}", emailType, toEmail, ex.getMessage(), ex);
            throw new IllegalStateException("Failed to send " + emailType + " email", ex);
        }
    }

    private String buildPasswordResetHtml(String userName, String otpCode, int expiryMinutes) {
        return """
                <html>
                  <body style="font-family: Arial, sans-serif; color: #1f2937;">
                    <p>Hi %s,</p>
                    <p>We received a request to reset your StayBooking password. Use the OTP below to continue:</p>
                    <p>
                      <span style="display:inline-block;padding:10px 16px;background:#0f766e;color:#ffffff;font-size:20px;font-weight:700;letter-spacing:4px;border-radius:6px;">%s</span>
                    </p>
                    <p>This OTP expires in %d minutes and can be used only once.</p>
                    <p>If you did not request this, please ignore this email.</p>
                  </body>
                </html>
                """.formatted(userName, otpCode, expiryMinutes);
    }

    private String buildNotificationHtml(String userName, String headline, String message) {
        return """
                <html>
                  <body style="font-family: Arial, sans-serif; color: #1f2937;">
                    <p>Hi %s,</p>
                    <p style="font-size: 18px; font-weight: 700; color: #0f766e;">%s</p>
                    <p>%s</p>
                    <p>Thank you,<br/>StayBooking Team</p>
                  </body>
                </html>
                """.formatted(userName, headline, message);
    }
}
