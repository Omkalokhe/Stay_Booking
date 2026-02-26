package com.dto;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@Data
public class UpdateHotelRequestDto {
    private String name;
    private String description;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;
    private BigDecimal rating;
    private Boolean replacePhotos;
    private String updatedby;
    private List<MultipartFile> photos;
}
