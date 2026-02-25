package com.serviceImpl;

import com.config.NotificationProperties;
import com.dto.MarkAllNotificationsReadResponseDto;
import com.dto.NotificationResponseDto;
import com.dto.PageResponseDto;
import com.entity.Booking;
import com.entity.Notification;
import com.entity.User;
import com.enums.BookingStatus;
import com.enums.NotificationChannel;
import com.enums.NotificationDeliveryStatus;
import com.enums.NotificationType;
import com.enums.PaymentStatus;
import com.exception.ResourceNotFoundException;
import com.repository.NotificationRepository;
import com.repository.UserRepository;
import com.service.EmailService;
import com.service.NotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
public class NotificationServiceImpl implements NotificationService {

    private static final Logger LOGGER = LoggerFactory.getLogger(NotificationServiceImpl.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final NotificationProperties notificationProperties;

    public NotificationServiceImpl(NotificationRepository notificationRepository,
                                   UserRepository userRepository,
                                   EmailService emailService,
                                   NotificationProperties notificationProperties) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.notificationProperties = notificationProperties;
    }

    @Override
    public void sendBookingCreatedNotifications(Booking booking) {
        String title = "Booking created";
        String message = "Booking #" + booking.getId() + " is created and waiting for payment confirmation.";
        dispatch(booking, NotificationType.BOOKING_CREATED, title, message, true);
    }

    @Override
    public void sendBookingUpdatedNotifications(Booking booking) {
        String title = "Booking updated";
        String message = "Booking #" + booking.getId() + " details have been updated.";
        dispatch(booking, NotificationType.BOOKING_UPDATED, title, message, true);
    }

    @Override
    public void sendBookingCancelledNotifications(Booking booking) {
        String title = "Booking cancelled";
        String message = "Booking #" + booking.getId() + " has been cancelled.";
        dispatch(booking, NotificationType.BOOKING_CANCELLED, title, message, true);
    }

    @Override
    public void sendBookingStateChangeNotifications(Booking booking, BookingStatus previousBookingStatus, PaymentStatus previousPaymentStatus) {
        if (booking.getBookingStatus() != previousBookingStatus) {
            String title = "Booking status changed";
            String message = "Booking #" + booking.getId() + " status changed from " + previousBookingStatus + " to " + booking.getBookingStatus() + ".";
            dispatch(booking, NotificationType.BOOKING_STATUS_CHANGED, title, message, true);
        }

        if (booking.getPaymentStatus() != previousPaymentStatus) {
            if (booking.getPaymentStatus() == PaymentStatus.SUCCESS) {
                dispatch(
                        booking,
                        NotificationType.PAYMENT_SUCCESS,
                        "Payment successful",
                        "Payment completed for booking #" + booking.getId() + ". Your booking is confirmed.",
                        true
                );
            } else if (booking.getPaymentStatus() == PaymentStatus.FAILED) {
                dispatch(
                        booking,
                        NotificationType.PAYMENT_FAILED,
                        "Payment failed",
                        "Payment failed for booking #" + booking.getId() + ". Please retry payment.",
                        true
                );
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponseDto<NotificationResponseDto> getMyNotifications(int page, int size, boolean unreadOnly) {
        User currentUser = getCurrentUser();
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, Math.min(size, 100));
        Pageable pageable = PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<Notification> notificationPage = unreadOnly
                ? notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(currentUser.getId(), pageable)
                : notificationRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId(), pageable);

        return PageResponseDto.<NotificationResponseDto>builder()
                .content(notificationPage.getContent().stream().map(this::toResponse).toList())
                .page(notificationPage.getNumber())
                .size(notificationPage.getSize())
                .totalElements(notificationPage.getTotalElements())
                .totalPages(notificationPage.getTotalPages())
                .first(notificationPage.isFirst())
                .last(notificationPage.isLast())
                .build();
    }

    @Override
    @Transactional
    public NotificationResponseDto markMyNotificationAsRead(long notificationId) {
        User currentUser = getCurrentUser();
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with id: " + notificationId));

        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(OffsetDateTime.now());
            notification = notificationRepository.save(notification);
        }

        return toResponse(notification);
    }

    @Override
    @Transactional
    public MarkAllNotificationsReadResponseDto markAllMyNotificationsAsRead() {
        User currentUser = getCurrentUser();
        int updated = notificationRepository.markAllRead(currentUser.getId(), OffsetDateTime.now());
        return new MarkAllNotificationsReadResponseDto(updated);
    }

    @Override
    @Transactional(readOnly = true)
    public long getMyUnreadCount() {
        User currentUser = getCurrentUser();
        return notificationRepository.countByUserIdAndIsReadFalse(currentUser.getId());
    }

    private void dispatch(Booking booking, NotificationType type, String title, String message, boolean sendEmail) {
        User user = booking.getUser();

        createAndStoreNotification(
                user,
                type,
                NotificationChannel.IN_APP,
                NotificationDeliveryStatus.SENT,
                title,
                message,
                "BOOKING",
                booking.getId()
        );

        if (!sendEmail || !notificationProperties.isEmailEnabled()) {
            return;
        }

        if (isBlank(user.getEmail())) {
            LOGGER.warn("Skipping email notification for userId={} due to missing email", user.getId());
            createAndStoreNotification(
                    user,
                    type,
                    NotificationChannel.EMAIL,
                    NotificationDeliveryStatus.FAILED,
                    title,
                    "Email delivery failed because no email address is available.",
                    "BOOKING",
                    booking.getId()
            );
            return;
        }

        try {
            emailService.sendNotificationEmail(user.getEmail(), user.getFname(), "StayBooking: " + title, title, message);
            createAndStoreNotification(
                    user,
                    type,
                    NotificationChannel.EMAIL,
                    NotificationDeliveryStatus.SENT,
                    title,
                    message,
                    "BOOKING",
                    booking.getId()
            );
        } catch (Exception ex) {
            LOGGER.error("Email notification failed for userId={} bookingId={}. Reason: {}",
                    user.getId(), booking.getId(), ex.getMessage(), ex);
            createAndStoreNotification(
                    user,
                    type,
                    NotificationChannel.EMAIL,
                    NotificationDeliveryStatus.FAILED,
                    title,
                    "Email delivery failed. Please check in-app notifications.",
                    "BOOKING",
                    booking.getId()
            );
        }
    }

    private void createAndStoreNotification(User user,
                                            NotificationType type,
                                            NotificationChannel channel,
                                            NotificationDeliveryStatus deliveryStatus,
                                            String title,
                                            String message,
                                            String referenceType,
                                            Integer referenceId) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setType(type);
        notification.setChannel(channel);
        notification.setDeliveryStatus(deliveryStatus);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setReferenceType(referenceType);
        notification.setReferenceId(referenceId);
        notification.setRead(false);
        notificationRepository.save(notification);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getName() == null || authentication.getName().trim().isEmpty()) {
            throw new IllegalStateException("Authenticated user not found in security context");
        }
        User user = userRepository.findByEmailIgnoreCase(authentication.getName());
        if (user == null) {
            throw new ResourceNotFoundException("Authenticated user not found");
        }
        return user;
    }

    private NotificationResponseDto toResponse(Notification notification) {
        return NotificationResponseDto.builder()
                .id(notification.getId())
                .type(notification.getType())
                .channel(notification.getChannel())
                .deliveryStatus(notification.getDeliveryStatus())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .referenceType(notification.getReferenceType())
                .referenceId(notification.getReferenceId())
                .isRead(notification.isRead())
                .createdAt(notification.getCreatedAt())
                .readAt(notification.getReadAt())
                .build();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
