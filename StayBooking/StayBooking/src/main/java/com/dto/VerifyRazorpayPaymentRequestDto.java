package com.dto;

import lombok.Data;

@Data
public class VerifyRazorpayPaymentRequestDto {
    private Integer bookingId;
    private String razorpayOrderId;
    private String razorpayPaymentId;
    private String razorpaySignature;
}
