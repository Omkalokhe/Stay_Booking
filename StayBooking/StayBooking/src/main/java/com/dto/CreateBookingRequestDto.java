package com.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateBookingRequestDto {
    private Integer userId;
    private Integer hotelId;
    private Integer roomId;
    private LocalDate checkInDate;
    private LocalDate checkOutDate;
    private Integer numberOfGuests;
}

