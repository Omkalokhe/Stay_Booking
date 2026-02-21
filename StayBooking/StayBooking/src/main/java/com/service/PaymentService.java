package com.service;

import com.dto.CreateRazorpayOrderRequestDto;
import com.dto.VerifyRazorpayPaymentRequestDto;
import org.springframework.http.ResponseEntity;

public interface PaymentService {
    ResponseEntity<?> createRazorpayOrder(CreateRazorpayOrderRequestDto requestDto);

    ResponseEntity<?> verifyRazorpayPayment(VerifyRazorpayPaymentRequestDto requestDto);
}
