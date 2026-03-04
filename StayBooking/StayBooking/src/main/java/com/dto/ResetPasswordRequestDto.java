package com.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ResetPasswordRequestDto {
    @NotBlank(message = "email is required")
    private String email;

    @NotBlank(message = "otp is required")
    private String otp;

    @NotBlank(message = "newPassword is required")
    private String newPassword;

    @NotBlank(message = "confirmPassword is required")
    private String confirmPassword;
}
