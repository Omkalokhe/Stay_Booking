package com.dto;

import com.enums.BookingStatus;
import com.enums.PaymentMethod;
import com.enums.PaymentStatus;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Data
@Builder
public class BookingResponseDto {
    private int id;
    private int userId;
    private String userEmail;
    private int hotelId;
    private String hotelName;
    private int roomId;
    private String roomType;
    private LocalDate checkInDate;
    private LocalDate checkOutDate;
    private int numberOfGuests;
    private BigDecimal totalAmount;
    private BookingStatus bookingStatus;
    private PaymentStatus paymentStatus;
    private PaymentMethod paymentMethod;
    private String paymentReference;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
