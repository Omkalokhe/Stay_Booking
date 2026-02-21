package com.controller;

import com.dto.CreateRazorpayOrderRequestDto;
import com.dto.VerifyRazorpayPaymentRequestDto;
import com.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments/razorpay")
@CrossOrigin(origins = "*")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/orders")
    public ResponseEntity<?> createOrder(@RequestBody CreateRazorpayOrderRequestDto requestDto) {
        return paymentService.createRazorpayOrder(requestDto);
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyPayment(@RequestBody VerifyRazorpayPaymentRequestDto requestDto) {
        return paymentService.verifyRazorpayPayment(requestDto);
    }
}
