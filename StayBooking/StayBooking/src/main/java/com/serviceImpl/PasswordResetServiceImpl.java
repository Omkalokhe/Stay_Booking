package com.serviceImpl;

import com.dto.ForgotPasswordRequestDto;
import com.dto.ResetPasswordRequestDto;
import com.entity.PasswordResetOtp;
import com.entity.User;
import com.repository.PasswordResetOtpRepository;
import com.repository.UserRepository;
import com.service.EmailService;
import com.service.PasswordResetService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;

@Service
public class PasswordResetServiceImpl implements PasswordResetService {

    private static final Logger LOGGER = LoggerFactory.getLogger(PasswordResetServiceImpl.class);
    private static final int MIN_PASSWORD_LENGTH = 8;

    private final UserRepository userRepository;
    private final PasswordResetOtpRepository passwordResetOtpRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final int otpExpiryMinutes;
    private final int maxOtpAttempts;
    private final SecureRandom secureRandom = new SecureRandom();

    public PasswordResetServiceImpl(UserRepository userRepository,
                                    PasswordResetOtpRepository passwordResetOtpRepository,
                                    PasswordEncoder passwordEncoder,
                                    EmailService emailService,
                                    @Value("${app.password-reset.otp-expiry-minutes:10}") int otpExpiryMinutes,
                                    @Value("${app.password-reset.max-otp-attempts:5}") int maxOtpAttempts) {
        this.userRepository = userRepository;
        this.passwordResetOtpRepository = passwordResetOtpRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.otpExpiryMinutes = otpExpiryMinutes;
        this.maxOtpAttempts = maxOtpAttempts;
    }

    @Override
    @Transactional
    public ResponseEntity<?> requestPasswordResetOtp(ForgotPasswordRequestDto forgotPasswordRequestDto) {
        if (forgotPasswordRequestDto == null || isBlank(forgotPasswordRequestDto.getEmail())) {
            return ResponseEntity.badRequest().body("Email is required");
        }

        String email = forgotPasswordRequestDto.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmailIgnoreCase(email);
        if (user == null) {
            LOGGER.info("Forgot password requested for non-registered email: {}", email);
            return ResponseEntity.ok("If this email exists, a password reset OTP has been sent");
        }
        LOGGER.info("Forgot password requested for registered email: {}", email);

        LocalDateTime now = LocalDateTime.now();
        invalidateActiveOtps(user, now);

        String rawOtp = generateOtp();
        String otpHash = hashOtp(rawOtp);

        PasswordResetOtp resetOtp = PasswordResetOtp.builder()
                .user(user)
                .otpHash(otpHash)
                .expiresAt(now.plusMinutes(otpExpiryMinutes))
                .used(false)
                .createdAt(now)
                .failedAttempts(0)
                .build();
        PasswordResetOtp savedOtp = passwordResetOtpRepository.save(resetOtp);
        LOGGER.info("Password reset OTP created for userId={} email={}", user.getId(), email);

        try {
            emailService.sendPasswordResetOtpEmail(email, user.getFname(), rawOtp, otpExpiryMinutes);
        } catch (RuntimeException ex) {
            passwordResetOtpRepository.delete(savedOtp);
            LOGGER.error("Failed to deliver password reset OTP email for {}", email, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Unable to send OTP right now. Please try again.");
        }

        return ResponseEntity.ok("If this email exists, a password reset OTP has been sent");
    }

    @Override
    @Transactional
    public ResponseEntity<?> resetPasswordWithOtp(ResetPasswordRequestDto resetPasswordRequestDto) {
        if (resetPasswordRequestDto == null
                || isBlank(resetPasswordRequestDto.getEmail())
                || isBlank(resetPasswordRequestDto.getOtp())
                || isBlank(resetPasswordRequestDto.getNewPassword())
                || isBlank(resetPasswordRequestDto.getConfirmPassword())) {
            return ResponseEntity.badRequest().body("Email, otp, newPassword and confirmPassword are required");
        }

        if (!resetPasswordRequestDto.getNewPassword().equals(resetPasswordRequestDto.getConfirmPassword())) {
            return ResponseEntity.badRequest().body("newPassword and confirmPassword do not match");
        }

        if (resetPasswordRequestDto.getNewPassword().length() < MIN_PASSWORD_LENGTH) {
            return ResponseEntity.badRequest().body("Password must be at least " + MIN_PASSWORD_LENGTH + " characters");
        }

        String email = resetPasswordRequestDto.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmailIgnoreCase(email);
        if (user == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid OTP or email");
        }

        LocalDateTime now = LocalDateTime.now();
        Optional<PasswordResetOtp> optionalOtp = passwordResetOtpRepository
                .findTopByUserAndUsedFalseAndExpiresAtAfterOrderByCreatedAtDesc(user, now);
        if (optionalOtp.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
        }

        PasswordResetOtp resetOtp = optionalOtp.get();
        if (resetOtp.getExpiresAt().isBefore(now)) {
            resetOtp.setUsed(true);
            resetOtp.setUsedAt(now);
            passwordResetOtpRepository.save(resetOtp);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
        }

        String inputOtpHash = hashOtp(resetPasswordRequestDto.getOtp().trim());
        if (!inputOtpHash.equals(resetOtp.getOtpHash())) {
            int failedAttempts = resetOtp.getFailedAttempts() + 1;
            resetOtp.setFailedAttempts(failedAttempts);
            if (failedAttempts >= maxOtpAttempts) {
                resetOtp.setUsed(true);
                resetOtp.setUsedAt(now);
            }
            passwordResetOtpRepository.save(resetOtp);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(failedAttempts >= maxOtpAttempts
                            ? "OTP is invalid and has been locked. Request a new OTP."
                            : "Invalid OTP");
        }

        user.setPassword(passwordEncoder.encode(resetPasswordRequestDto.getNewPassword()));
        userRepository.save(user);

        resetOtp.setUsed(true);
        resetOtp.setUsedAt(now);
        passwordResetOtpRepository.save(resetOtp);
        invalidateActiveOtps(user, now);

        return ResponseEntity.ok("Password reset successful");
    }

    private void invalidateActiveOtps(User user, LocalDateTime now) {
        List<PasswordResetOtp> activeOtps = passwordResetOtpRepository
                .findByUserAndUsedFalseAndExpiresAtAfter(user, now);
        for (PasswordResetOtp otp : activeOtps) {
            otp.setUsed(true);
            otp.setUsedAt(now);
        }
        if (!activeOtps.isEmpty()) {
            passwordResetOtpRepository.saveAll(activeOtps);
        }
    }

    private String generateOtp() {
        int otp = 1000 + secureRandom.nextInt(9000);
        return String.valueOf(otp);
    }

    private String hashOtp(String rawOtp) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(rawOtp.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashBytes);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 algorithm unavailable", ex);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
