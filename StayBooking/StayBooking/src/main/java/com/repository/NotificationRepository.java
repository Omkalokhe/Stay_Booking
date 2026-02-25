package com.repository;

import com.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.Optional;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Page<Notification> findByUserIdOrderByCreatedAtDesc(int userId, Pageable pageable);

    Page<Notification> findByUserIdAndIsReadFalseOrderByCreatedAtDesc(int userId, Pageable pageable);

    Optional<Notification> findByIdAndUserId(long notificationId, int userId);

    long countByUserIdAndIsReadFalse(int userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update Notification n
            set n.isRead = true,
                n.readAt = :readAt
            where n.user.id = :userId
              and n.isRead = false
            """)
    int markAllRead(@Param("userId") int userId, @Param("readAt") OffsetDateTime readAt);
}
