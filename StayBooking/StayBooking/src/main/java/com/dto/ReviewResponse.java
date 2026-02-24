package com.dto;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@Builder
public class ReviewResponse {
    private int id;
    private int hotelId;
    private int userId;
    private String userName;
    private String reviewText;
    private int rating;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;


}
