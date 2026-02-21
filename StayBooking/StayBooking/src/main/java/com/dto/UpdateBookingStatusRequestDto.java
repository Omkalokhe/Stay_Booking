package com.dto;

import com.enums.BookingStatus;
import com.enums.PaymentStatus;
import lombok.Data;

@Data
public class UpdateBookingStatusRequestDto {
    private BookingStatus bookingStatus;
    private PaymentStatus paymentStatus;
}

