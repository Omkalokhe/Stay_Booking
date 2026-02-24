package com.serviceImpl;

import com.dto.ReviewRequest;
import com.dto.ReviewResponse;
import com.entity.Hotel;
import com.entity.Review;
import com.entity.User;
import com.exception.DuplicateReviewException;
import com.exception.ResourceNotFoundException;
import com.repository.HotelRepository;
import com.repository.ReviewRepository;
import com.repository.UserRepository;
import com.service.ReviewService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final HotelRepository hotelRepository;
    private final UserRepository userRepository;

    public ReviewServiceImpl(
            ReviewRepository reviewRepository,
            HotelRepository hotelRepository,
            UserRepository userRepository
    ) {
        this.reviewRepository = reviewRepository;
        this.hotelRepository = hotelRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public ReviewResponse createReview(ReviewRequest request) {
        Hotel hotel = hotelRepository.findById(request.getHotelId())
                .orElseThrow(() -> new ResourceNotFoundException("Hotel not found with id: " + request.getHotelId()));

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + request.getUserId()));

        boolean duplicateReviewExists = reviewRepository.existsByHotelIdAndUserId(hotel.getId(), user.getId());
        if (duplicateReviewExists) {
            throw new DuplicateReviewException(
                    "User with id " + user.getId() + " has already reviewed hotel with id " + hotel.getId()
            );
        }

        Review review = new Review();
        review.setHotel(hotel);
        review.setUser(user);
        review.setReviewText(request.getReviewText().trim());
        review.setRating(request.getRating());

        Review savedReview = reviewRepository.save(review);
        recalculateAndUpdateHotelRating(hotel);

        return mapToResponse(savedReview);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReviewResponse> getReviewsByHotelId(int hotelId) {
        if (!hotelRepository.existsById(hotelId)) {
            throw new ResourceNotFoundException("Hotel not found with id: " + hotelId);
        }

        return reviewRepository.findByHotelIdOrderByCreatedAtDesc(hotelId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    @Transactional
    public void deleteReview(int reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with id: " + reviewId));

        Hotel hotel = review.getHotel();
        reviewRepository.delete(review);
        recalculateAndUpdateHotelRating(hotel);
    }

    private void recalculateAndUpdateHotelRating(Hotel hotel) {
        Double averageRating = reviewRepository.findAverageRatingByHotelId(hotel.getId());
        if (averageRating == null) {
            hotel.setRating(null);
        } else {
            BigDecimal roundedRating = BigDecimal.valueOf(averageRating).setScale(1, RoundingMode.HALF_UP);
            hotel.setRating(roundedRating);
        }
        hotelRepository.save(hotel);
    }

    private ReviewResponse mapToResponse(Review review) {
        String firstName = review.getUser().getFname() == null ? "" : review.getUser().getFname().trim();
        String lastName = review.getUser().getLname() == null ? "" : review.getUser().getLname().trim();
        String userName = (firstName + " " + lastName).trim();

        return ReviewResponse.builder()
                .id(review.getId())
                .hotelId(review.getHotel().getId())
                .userId(review.getUser().getId())
                .userName(userName.isEmpty() ? null : userName)
                .reviewText(review.getReviewText())
                .rating(review.getRating())
                .createdAt(review.getCreatedAt())
                .updatedAt(review.getUpdatedAt())
                .build();
    }


}
