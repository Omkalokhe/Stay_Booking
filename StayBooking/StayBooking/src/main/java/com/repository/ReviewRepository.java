package com.repository;

import com.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Integer>, JpaSpecificationExecutor<Review> {

    List<Review> findByHotelIdOrderByCreatedAtDesc(int hotelId);

    boolean existsByHotelIdAndUserId(int hotelId, int userId);

    @Query("select avg(r.rating) from Review r where r.hotel.id = :hotelId")
    Double findAverageRatingByHotelId(@Param("hotelId") int hotelId);


}
