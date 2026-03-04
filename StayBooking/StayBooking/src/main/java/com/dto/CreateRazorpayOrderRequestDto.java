package com.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateRazorpayOrderRequestDto {
    @NotNull(message = "bookingId is required")
    private Integer bookingId;
}
