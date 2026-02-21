package com.controller;

import com.dto.CreateBookingRequestDto;
import com.dto.UpdateBookingRequestDto;
import com.dto.UpdateBookingStatusRequestDto;
import com.enums.BookingStatus;
import com.enums.PaymentStatus;
import com.service.BookingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @PostMapping
    public ResponseEntity<?> createBooking(@RequestBody CreateBookingRequestDto requestDto) {
        return bookingService.createBooking(requestDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getBookingById(@PathVariable int id) {
        return bookingService.getBookingById(id);
    }

    @GetMapping
    public ResponseEntity<?> getBookings(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) Integer userId,
            @RequestParam(required = false) Integer hotelId,
            @RequestParam(required = false) Integer roomId,
            @RequestParam(required = false) BookingStatus bookingStatus,
            @RequestParam(required = false) PaymentStatus paymentStatus,
            @RequestParam(required = false) LocalDate checkInFrom,
            @RequestParam(required = false) LocalDate checkOutTo
    ) {
        return bookingService.getBookings(
                page, size, sortBy, direction, userId, hotelId, roomId, bookingStatus, paymentStatus, checkInFrom, checkOutTo
        );
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateBooking(@PathVariable int id, @RequestBody UpdateBookingRequestDto requestDto) {
        return bookingService.updateBooking(id, requestDto);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateBookingStatus(@PathVariable int id, @RequestBody UpdateBookingStatusRequestDto requestDto) {
        return bookingService.updateBookingStatus(id, requestDto);
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelBooking(@PathVariable int id) {
        return bookingService.cancelBooking(id);
    }
}
