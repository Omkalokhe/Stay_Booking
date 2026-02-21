package com.service;

import com.dto.AdminUpdateRoomStatusRequestDto;
import com.dto.AdminUpdateUserAccessRequestDto;
import com.enums.Role;
import com.enums.UserStatus;
import org.springframework.http.ResponseEntity;

public interface AdminService {

    ResponseEntity<?> getUsers(int page, int size, String sortBy, String direction, Role role, UserStatus status, String search);

    ResponseEntity<?> updateUserAccess(int userId, AdminUpdateUserAccessRequestDto requestDto);

    ResponseEntity<?> deleteUser(int userId, boolean hardDelete, String deletedBy);

    ResponseEntity<?> getHotels(int page, int size, String sortBy, String direction, String city, String country, String search);

    ResponseEntity<?> deleteHotel(int hotelId, String deletedBy);

    ResponseEntity<?> getRooms(int page, int size, String sortBy, String direction, String hotelName, Boolean available, String search);

    ResponseEntity<?> updateRoomStatus(int roomId, AdminUpdateRoomStatusRequestDto requestDto);

    ResponseEntity<?> deleteRoom(int roomId);
}

