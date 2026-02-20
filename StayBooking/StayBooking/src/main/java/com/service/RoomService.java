package com.service;

import com.dto.CreateRoomRequestDto;
import com.dto.UpdateRoomRequestDto;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;

public interface RoomService {
    ResponseEntity<?> createRoom(CreateRoomRequestDto requestDto);

    ResponseEntity<?> getRoomById(int id);

    ResponseEntity<?> getRooms(int page, int size, String sortBy, String direction, String hotelName, Boolean available, String search);

    ResponseEntity<?> updateRoom(int id, UpdateRoomRequestDto requestDto);

    ResponseEntity<?> deleteRoom(int id);

    ResponseEntity<Resource> getRoomPhoto(String filename);
}
