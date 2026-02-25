package com.service;

import com.dto.MarkAllNotificationsReadResponseDto;
import com.dto.NotificationResponseDto;
import com.dto.PageResponseDto;
import com.entity.Booking;
import com.enums.BookingStatus;
import com.enums.PaymentStatus;

public interface NotificationService {

    void sendBookingCreatedNotifications(Booking booking);

    void sendBookingUpdatedNotifications(Booking booking);

    void sendBookingCancelledNotifications(Booking booking);

    void sendBookingStateChangeNotifications(Booking booking, BookingStatus previousBookingStatus, PaymentStatus previousPaymentStatus);

    PageResponseDto<NotificationResponseDto> getMyNotifications(int page, int size, boolean unreadOnly);

    NotificationResponseDto markMyNotificationAsRead(long notificationId);

    MarkAllNotificationsReadResponseDto markAllMyNotificationsAsRead();

    long getMyUnreadCount();
}
