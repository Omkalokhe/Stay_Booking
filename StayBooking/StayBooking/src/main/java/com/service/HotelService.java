package com.service;

import com.dto.CreateHotelRequestDto;
import com.dto.UpdateHotelRequestDto;
import org.springframework.http.ResponseEntity;

public interface HotelService {
    ResponseEntity<?> createHotel(CreateHotelRequestDto requestDto);

    ResponseEntity<?> getHotelById(int id);

    ResponseEntity<?> getHotels(int page, int size, String sortBy, String direction, String city, String country, String search);

    ResponseEntity<?> updateHotel(int id, UpdateHotelRequestDto requestDto);

    ResponseEntity<?> deleteHotel(int id, String deletedBy);
}
