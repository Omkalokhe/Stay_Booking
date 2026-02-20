package com.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateHotelRequestDto {
    private String name;
    private String description;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;
    private BigDecimal rating;
    private String createdby;
}
