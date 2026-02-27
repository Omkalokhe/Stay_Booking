package com.enums;

public enum PaymentMethod {
    RAZORPAY;

    public static PaymentMethod fromDatabaseValue(String rawValue) {
        if (rawValue == null || rawValue.trim().isEmpty()) {
            return null;
        }
        return RAZORPAY;
    }
}
