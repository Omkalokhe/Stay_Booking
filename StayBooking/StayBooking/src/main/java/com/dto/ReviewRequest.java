package com.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReviewRequest {

    @NotNull(message = "hotelId is required")
    private Integer hotelId;

    @NotNull(message = "userId is required")
    private Integer userId;

    @NotBlank(message = "reviewText is required")
    @Size(max = 2000, message = "reviewText must be at most 2000 characters")
    private String reviewText;

    @NotNull(message = "rating is required")
    @Min(value = 1, message = "rating must be between 1 and 5")
    @Max(value = 5, message = "rating must be between 1 and 5")
    private Integer rating;
}
