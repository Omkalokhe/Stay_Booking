package com.dto;

import com.enums.BookingStatus;
import com.enums.PaymentStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class VerifyRazorpayPaymentResponseDto {
    private int bookingId;
    private String razorpayOrderId;
    private String razorpayPaymentId;
    private PaymentStatus paymentStatus;
    private BookingStatus bookingStatus;
    private String frontendMessage;
}
