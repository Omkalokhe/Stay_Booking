package com.repository;

import com.entity.PasswordResetOtp;
import com.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PasswordResetOtpRepository extends JpaRepository<PasswordResetOtp, Long> {

    List<PasswordResetOtp> findByUserAndUsedFalseAndExpiresAtAfter(User user, LocalDateTime now);

    Optional<PasswordResetOtp> findTopByUserAndUsedFalseAndExpiresAtAfterOrderByCreatedAtDesc(User user, LocalDateTime now);
}
