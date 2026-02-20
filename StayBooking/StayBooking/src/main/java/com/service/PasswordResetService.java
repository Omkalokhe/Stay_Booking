package com.service;

import com.dto.ForgotPasswordRequestDto;
import com.dto.ResetPasswordRequestDto;
import org.springframework.http.ResponseEntity;

public interface PasswordResetService {
    ResponseEntity<?> requestPasswordResetOtp(ForgotPasswordRequestDto forgotPasswordRequestDto);

    ResponseEntity<?> resetPasswordWithOtp(ResetPasswordRequestDto resetPasswordRequestDto);
}
