package com.serviceImpl;

import com.config.RazorpayProperties;
import com.dto.CreateRazorpayOrderRequestDto;
import com.dto.CreateRazorpayOrderResponseDto;
import com.dto.VerifyRazorpayPaymentRequestDto;
import com.dto.VerifyRazorpayPaymentResponseDto;
import com.entity.Booking;
import com.entity.PaymentTransaction;
import com.enums.BookingStatus;
import com.enums.PaymentMethod;
import com.enums.PaymentStatus;
import com.repository.BookingRepository;
import com.repository.PaymentTransactionRepository;
import com.service.NotificationService;
import com.service.PaymentService;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class PaymentServiceImpl implements PaymentService {

    private static final String RAZORPAY_ORDERS_URL = "https://api.razorpay.com/v1/orders";
    private static final String HMAC_SHA256 = "HmacSHA256";

    private final BookingRepository bookingRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final RazorpayProperties razorpayProperties;
    private final NotificationService notificationService;
    private final RestTemplate restTemplate = new RestTemplate();

    public PaymentServiceImpl(BookingRepository bookingRepository,
                              PaymentTransactionRepository paymentTransactionRepository,
                              RazorpayProperties razorpayProperties,
                              NotificationService notificationService) {
        this.bookingRepository = bookingRepository;
        this.paymentTransactionRepository = paymentTransactionRepository;
        this.razorpayProperties = razorpayProperties;
        this.notificationService = notificationService;
    }

    @Override
    @Transactional
    public ResponseEntity<?> createRazorpayOrder(CreateRazorpayOrderRequestDto requestDto) {
        if (requestDto == null || requestDto.getBookingId() == null) {
            return ResponseEntity.badRequest().body("bookingId is required");
        }
        if (isBlank(razorpayProperties.getKeyId()) || isBlank(razorpayProperties.getKeySecret())) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Razorpay keys are not configured on server");
        }

        Optional<Booking> optionalBooking = bookingRepository.findById(requestDto.getBookingId());
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Booking not found with id: " + requestDto.getBookingId());
        }

        Booking booking = optionalBooking.get();
        if (isTerminalBooking(booking.getBookingStatus())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Cannot create payment order for booking status: " + booking.getBookingStatus());
        }
        if (booking.getPaymentStatus() == PaymentStatus.SUCCESS) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Payment is already completed for this booking");
        }

        long amountInPaise = toPaise(booking.getTotalAmount());
        String currency = normalizeCurrency(razorpayProperties.getCurrency());

        Map<String, Object> orderRequest = new LinkedHashMap<>();
        orderRequest.put("amount", amountInPaise);
        orderRequest.put("currency", currency);
        orderRequest.put("receipt", "booking-" + booking.getId() + "-" + Instant.now().toEpochMilli());
        orderRequest.put("notes", Map.of("booking_id", String.valueOf(booking.getId())));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", buildBasicAuth(razorpayProperties.getKeyId(), razorpayProperties.getKeySecret()));

        Map<String, Object> orderResponse;
        try {
            ResponseEntity<Map> razorpayResponse = restTemplate.exchange(
                    RAZORPAY_ORDERS_URL,
                    HttpMethod.POST,
                    new HttpEntity<>(orderRequest, headers),
                    Map.class
            );
            orderResponse = razorpayResponse.getBody();
        } catch (HttpStatusCodeException ex) {
            String providerError = ex.getResponseBodyAsString();
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Failed to create Razorpay order: " + providerError);
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Failed to create Razorpay order: " + ex.getMessage());
        }

        if (orderResponse == null || orderResponse.get("id") == null) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Razorpay order creation returned invalid response");
        }

        String razorpayOrderId = String.valueOf(orderResponse.get("id"));

        PaymentTransaction tx = new PaymentTransaction();
        tx.setBooking(booking);
        tx.setPaymentMethod(PaymentMethod.RAZORPAY);
        tx.setPaymentStatus(PaymentStatus.PENDING);
        tx.setAmount(booking.getTotalAmount());
        tx.setCurrency(currency);
        tx.setProviderOrderId(razorpayOrderId);
        paymentTransactionRepository.save(tx);

        booking.setPaymentMethod(PaymentMethod.RAZORPAY);
        booking.setPaymentStatus(PaymentStatus.PENDING);
        booking.setPaymentReference(razorpayOrderId);
        bookingRepository.save(booking);

        CreateRazorpayOrderResponseDto responseDto = CreateRazorpayOrderResponseDto.builder()
                .bookingId(booking.getId())
                .orderId(razorpayOrderId)
                .keyId(razorpayProperties.getKeyId())
                .amountInPaise(amountInPaise)
                .currency(currency)
                .paymentMethod(PaymentMethod.RAZORPAY)
                .paymentStatus(booking.getPaymentStatus())
                .bookingStatus(booking.getBookingStatus())
                .frontendMessage("Order created. Open Razorpay checkout to complete payment.")
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    }

    @Override
    @Transactional
    public ResponseEntity<?> verifyRazorpayPayment(VerifyRazorpayPaymentRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (requestDto.getBookingId() == null
                || isBlank(requestDto.getRazorpayOrderId())
                || isBlank(requestDto.getRazorpayPaymentId())
                || isBlank(requestDto.getRazorpaySignature())) {
            return ResponseEntity.badRequest()
                    .body("bookingId, razorpayOrderId, razorpayPaymentId and razorpaySignature are required");
        }
        if (isBlank(razorpayProperties.getKeySecret())) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Razorpay key secret is not configured on server");
        }

        Optional<Booking> optionalBooking = bookingRepository.findById(requestDto.getBookingId());
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Booking not found with id: " + requestDto.getBookingId());
        }
        Booking booking = optionalBooking.get();

        Optional<PaymentTransaction> optionalTx = paymentTransactionRepository.findByProviderOrderId(requestDto.getRazorpayOrderId());
        if (optionalTx.isEmpty() || optionalTx.get().getBooking().getId() != booking.getId()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("No payment order found for this booking and razorpayOrderId");
        }

        PaymentTransaction tx = optionalTx.get();
        if (tx.getPaymentStatus() == PaymentStatus.SUCCESS && requestDto.getRazorpayPaymentId().equals(tx.getProviderPaymentId())) {
            VerifyRazorpayPaymentResponseDto alreadyDone = buildVerifyResponse(
                    booking,
                    requestDto.getRazorpayOrderId(),
                    requestDto.getRazorpayPaymentId(),
                    "Payment already verified."
            );
            return ResponseEntity.ok(alreadyDone);
        }

        String expectedSignature = hmacSha256Hex(
                requestDto.getRazorpayOrderId() + "|" + requestDto.getRazorpayPaymentId(),
                razorpayProperties.getKeySecret()
        );

        BookingStatus previousBookingStatus = booking.getBookingStatus();
        PaymentStatus previousPaymentStatus = booking.getPaymentStatus();

        if (!expectedSignature.equals(requestDto.getRazorpaySignature())) {
            tx.setPaymentStatus(PaymentStatus.FAILED);
            tx.setProviderPaymentId(requestDto.getRazorpayPaymentId());
            tx.setProviderSignature(requestDto.getRazorpaySignature());
            tx.setErrorCode("SIGNATURE_MISMATCH");
            tx.setErrorDescription("Razorpay signature verification failed");
            paymentTransactionRepository.save(tx);

            booking.setPaymentStatus(PaymentStatus.FAILED);
            bookingRepository.save(booking);
            notificationService.sendBookingStateChangeNotifications(booking, previousBookingStatus, previousPaymentStatus);

            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Invalid payment signature. Payment verification failed.");
        }

        tx.setPaymentStatus(PaymentStatus.SUCCESS);
        tx.setProviderPaymentId(requestDto.getRazorpayPaymentId());
        tx.setProviderSignature(requestDto.getRazorpaySignature());
        tx.setErrorCode(null);
        tx.setErrorDescription(null);
        paymentTransactionRepository.save(tx);

        booking.setPaymentMethod(PaymentMethod.RAZORPAY);
        booking.setPaymentStatus(PaymentStatus.SUCCESS);
        booking.setPaymentReference(requestDto.getRazorpayPaymentId());
        if (booking.getBookingStatus() == BookingStatus.PENDING) {
            booking.setBookingStatus(BookingStatus.CONFIRMED);
        }
        bookingRepository.save(booking);
        notificationService.sendBookingStateChangeNotifications(booking, previousBookingStatus, previousPaymentStatus);

        VerifyRazorpayPaymentResponseDto responseDto = buildVerifyResponse(
                booking,
                requestDto.getRazorpayOrderId(),
                requestDto.getRazorpayPaymentId(),
                "Payment successful. Booking confirmed."
        );
        return ResponseEntity.ok(responseDto);
    }

    private VerifyRazorpayPaymentResponseDto buildVerifyResponse(Booking booking,
                                                                 String razorpayOrderId,
                                                                 String razorpayPaymentId,
                                                                 String frontendMessage) {
        return VerifyRazorpayPaymentResponseDto.builder()
                .bookingId(booking.getId())
                .razorpayOrderId(razorpayOrderId)
                .razorpayPaymentId(razorpayPaymentId)
                .paymentStatus(booking.getPaymentStatus())
                .bookingStatus(booking.getBookingStatus())
                .frontendMessage(frontendMessage)
                .build();
    }

    private boolean isTerminalBooking(BookingStatus status) {
        return status == BookingStatus.CANCELLED || status == BookingStatus.COMPLETED || status == BookingStatus.NO_SHOW;
    }

    private long toPaise(BigDecimal amount) {
        return amount.multiply(BigDecimal.valueOf(100)).longValueExact();
    }

    private String normalizeCurrency(String currency) {
        if (isBlank(currency)) {
            return "INR";
        }
        return currency.trim().toUpperCase(Locale.ROOT);
    }

    private String buildBasicAuth(String keyId, String keySecret) {
        String raw = keyId + ":" + keySecret;
        return "Basic " + Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    private String hmacSha256Hex(String data, String secret) {
        try {
            Mac sha256Hmac = Mac.getInstance(HMAC_SHA256);
            SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_SHA256);
            sha256Hmac.init(secretKey);
            byte[] digest = sha256Hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to compute payment signature", ex);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
