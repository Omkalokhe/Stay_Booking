package com.controller;

import com.dto.ReviewRequest;
import com.dto.ReviewResponse;
import com.service.ReviewService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
@CrossOrigin(origins = "*")
@Validated
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping
    public ResponseEntity<ReviewResponse> createReview(@Valid @RequestBody ReviewRequest request) {
        ReviewResponse response = reviewService.createReview(request);
        return ResponseEntity.status(201).body(response);
    }


    @GetMapping("/hotel/{id}")
    public ResponseEntity<List<ReviewResponse>> getReviewsByHotel(@PathVariable("id") @Positive int id) {
        return ResponseEntity.ok(reviewService.getReviewsByHotelId(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteReview(@PathVariable("id") @Positive int id) {
        reviewService.deleteReview(id);
        return ResponseEntity.noContent().build();
    }


}
