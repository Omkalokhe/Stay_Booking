package com.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HotelResponseDto {
    private int id;
    private String name;
    private String description;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;
    private BigDecimal rating;
    private List<String> photoUrls;
    private String createdat;
    private String updatedat;
    private String createdby;
    private String updatedby;
}
