package com.controller;

import com.dto.AdminUpdateRoomStatusRequestDto;
import com.dto.AdminUpdateUserAccessRequestDto;
import com.enums.Role;
import com.enums.UserStatus;
import com.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/users")
    public ResponseEntity<?> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) String search
    ) {
        return adminService.getUsers(page, size, sortBy, direction, role, status, search);
    }

    @GetMapping("/vendors")
    public ResponseEntity<?> getVendors(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) String search
    ) {
        return adminService.getUsers(page, size, sortBy, direction, Role.VENDOR, status, search);
    }

    @PutMapping("/users/{userId}/access")
    public ResponseEntity<?> updateUserAccess(
            @PathVariable int userId,
            @RequestBody AdminUpdateUserAccessRequestDto requestDto
    ) {
        return adminService.updateUserAccess(userId, requestDto);
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<?> deleteUser(
            @PathVariable int userId,
            @RequestParam(defaultValue = "false") boolean hardDelete,
            @RequestParam(required = false) String deletedBy
    ) {
        return adminService.deleteUser(userId, hardDelete, deletedBy);
    }

    @GetMapping("/hotels")
    public ResponseEntity<?> getHotels(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String search
    ) {
        return adminService.getHotels(page, size, sortBy, direction, city, country, search);
    }

    @DeleteMapping("/hotels/{hotelId}")
    public ResponseEntity<?> deleteHotel(
            @PathVariable int hotelId,
            @RequestParam(required = false) String deletedBy
    ) {
        return adminService.deleteHotel(hotelId, deletedBy);
    }

    @GetMapping("/rooms")
    public ResponseEntity<?> getRooms(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) String hotelName,
            @RequestParam(required = false) Boolean available,
            @RequestParam(required = false) String search
    ) {
        return adminService.getRooms(page, size, sortBy, direction, hotelName, available, search);
    }

    @PutMapping("/rooms/{roomId}/status")
    public ResponseEntity<?> updateRoomStatus(
            @PathVariable int roomId,
            @RequestBody AdminUpdateRoomStatusRequestDto requestDto
    ) {
        return adminService.updateRoomStatus(roomId, requestDto);
    }

    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<?> deleteRoom(@PathVariable int roomId) {
        return adminService.deleteRoom(roomId);
    }

    @GetMapping("/reviews")
    public ResponseEntity<?> getReviews(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(defaultValue = "desc") String direction,
            @RequestParam(required = false) Integer rating,
            @RequestParam(required = false) String search
    ) {
        return adminService.getReviews(page, size, sortBy, direction, rating, search);
    }
}

