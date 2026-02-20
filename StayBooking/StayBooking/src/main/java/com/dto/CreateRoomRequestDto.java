package com.dto;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@Data
public class CreateRoomRequestDto {
    private Integer hotelId;
    private String hotelName;
    private String roomType;
    private String description;
    private BigDecimal price;
    private Boolean available;
    private String createdby;
    private List<MultipartFile> photos;
}
