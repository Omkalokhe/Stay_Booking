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
public class RoomResponseDto {
    private int id;
    private int hotelId;
    private String hotelName;
    private String roomType;
    private String description;
    private BigDecimal price;
    private boolean available;
    private List<String> photoUrls;
    private String createdat;
    private String updatedat;
    private String createdby;
    private String updatedby;
}
