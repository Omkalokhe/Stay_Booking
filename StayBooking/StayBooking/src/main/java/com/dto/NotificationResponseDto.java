package com.dto;

import com.enums.NotificationChannel;
import com.enums.NotificationDeliveryStatus;
import com.enums.NotificationType;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@Builder
public class NotificationResponseDto {
    private long id;
    private NotificationType type;
    private NotificationChannel channel;
    private NotificationDeliveryStatus deliveryStatus;
    private String title;
    private String message;
    private String referenceType;
    private Integer referenceId;
    private boolean isRead;
    private OffsetDateTime createdAt;
    private OffsetDateTime readAt;
}
