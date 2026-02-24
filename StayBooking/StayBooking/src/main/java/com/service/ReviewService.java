package com.service;

import com.dto.ReviewRequest;
import com.dto.ReviewResponse;
import org.springframework.data.domain.Page;

import java.util.List;

public interface ReviewService {
    ReviewResponse createReview(ReviewRequest request);

    List<ReviewResponse> getReviewsByHotelId(int hotelId);

    void deleteReview(int reviewId);

}
