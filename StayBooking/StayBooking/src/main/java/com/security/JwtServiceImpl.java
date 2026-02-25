package com.security;

import com.config.JwtProperties;
import com.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Map;

@Service
public class JwtServiceImpl implements JwtService {

    private final JwtProperties jwtProperties;
    private Key signingKey;

    public JwtServiceImpl(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
    }

    @PostConstruct
    void validateAndInitKey() {
        byte[] keyBytes;
        try {
            keyBytes = Decoders.BASE64.decode(jwtProperties.getBase64Secret());
        } catch (IllegalArgumentException ex) {
            throw new IllegalStateException("app.jwt.base64-secret must be valid Base64", ex);
        }

        if (keyBytes.length < 32) {
            throw new IllegalStateException("app.jwt.base64-secret must decode to at least 32 bytes");
        }
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    @Override
    public String generateAccessToken(User user) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(jwtProperties.getAccessTokenExpiryMinutes(), ChronoUnit.MINUTES);

        Map<String, Object> claims = Map.of(
                "uid", user.getId(),
                "role", user.getRole().name(),
                "status", user.getStatus().name()
        );

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(user.getEmail())
                .setIssuer(jwtProperties.getIssuer())
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiresAt))
                .signWith(signingKey)
                .compact();
    }

    @Override
    public String extractUsername(String token) {
        return parseClaims(token).getSubject();
    }

    @Override
    public boolean isTokenValid(String token, String expectedUsername) {
        try {
            Claims claims = parseClaims(token);
            boolean sameUser = claims.getSubject().equalsIgnoreCase(expectedUsername);
            boolean notExpired = claims.getExpiration().after(new Date());
            boolean sameIssuer = jwtProperties.getIssuer().equals(claims.getIssuer());
            return sameUser && notExpired && sameIssuer;
        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    @Override
    public long getAccessTokenExpiryMinutes() {
        return jwtProperties.getAccessTokenExpiryMinutes();
    }

    private Claims parseClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
}
