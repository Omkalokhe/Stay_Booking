package com.dto;

import com.enums.BookingStatus;
import com.enums.PaymentMethod;
import com.enums.PaymentStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CreateRazorpayOrderResponseDto {
    private int bookingId;
    private String orderId;
    private String keyId;
    private long amountInPaise;
    private String currency;
    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private BookingStatus bookingStatus;
    private String frontendMessage;
}
