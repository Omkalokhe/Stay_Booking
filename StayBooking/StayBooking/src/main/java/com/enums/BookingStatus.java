package com.enums;

public enum BookingStatus {
    PENDING,        // Booking created but not confirmed
    CONFIRMED,      // Payment done and room reserved
    CANCELLED,      // Booking cancelled
    COMPLETED,      // Stay completed
    NO_SHOW         // Customer did not check in

}
