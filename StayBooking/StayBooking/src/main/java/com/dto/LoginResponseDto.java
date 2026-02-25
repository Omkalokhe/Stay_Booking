package com.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponseDto {
    private String message;
    private UserDto user;
    private String tokenType;
    private String accessToken;
    private long expiresInMinutes;
}
