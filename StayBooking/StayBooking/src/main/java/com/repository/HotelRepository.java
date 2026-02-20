package com.repository;

import com.entity.Hotel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HotelRepository extends JpaRepository<Hotel, Integer> {
    Page<Hotel> findByCityIgnoreCaseContainingAndCountryIgnoreCaseContainingAndNameIgnoreCaseContaining(
            String city, String country, String name, Pageable pageable
    );

    List<Hotel> findByNameIgnoreCase(String name);
}
