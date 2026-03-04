package com.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateBookingRequestDto {
    @NotNull(message = "userId is required")
    private Integer userId;

    @NotNull(message = "hotelId is required")
    private Integer hotelId;

    @NotNull(message = "roomId is required")
    private Integer roomId;

    @NotNull(message = "checkInDate is required")
    private LocalDate checkInDate;

    @NotNull(message = "checkOutDate is required")
    private LocalDate checkOutDate;

    @NotNull(message = "numberOfGuests is required")
    @Positive(message = "numberOfGuests must be greater than 0")
    private Integer numberOfGuests;
}

