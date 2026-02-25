package com.security;

import com.entity.User;

public interface JwtService {
    String generateAccessToken(User user);
    String extractUsername(String token);
    boolean isTokenValid(String token, String expectedUsername);
    long getAccessTokenExpiryMinutes();
}
