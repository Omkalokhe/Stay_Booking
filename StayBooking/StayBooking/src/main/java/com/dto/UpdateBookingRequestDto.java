package com.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateBookingRequestDto {
    private LocalDate checkInDate;
    private LocalDate checkOutDate;
    private Integer numberOfGuests;
}

