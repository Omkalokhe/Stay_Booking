package com.service;

import com.dto.CreateBookingRequestDto;
import com.dto.UpdateBookingRequestDto;
import com.dto.UpdateBookingStatusRequestDto;
import com.enums.BookingStatus;
import com.enums.PaymentStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;

public interface BookingService {

    ResponseEntity<?> createBooking(CreateBookingRequestDto requestDto);

    ResponseEntity<?> getBookingById(int id);

    ResponseEntity<?> getBookings(int page, int size, String sortBy, String direction,
                                  Integer userId, Integer hotelId, Integer roomId,
                                  BookingStatus bookingStatus, PaymentStatus paymentStatus,
                                  LocalDate checkInFrom, LocalDate checkOutTo);

    ResponseEntity<?> updateBooking(int id, UpdateBookingRequestDto requestDto);

    ResponseEntity<?> updateBookingStatus(int id, UpdateBookingStatusRequestDto requestDto);

    ResponseEntity<?> cancelBooking(int id);

    ResponseEntity<?> deleteBooking(int id);
}

