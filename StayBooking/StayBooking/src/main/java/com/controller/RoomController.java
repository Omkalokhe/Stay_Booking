package com.controller;

import com.dto.CreateRoomRequestDto;
import com.dto.UpdateRoomRequestDto;
import com.service.RoomService;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/rooms")
@CrossOrigin(origins = "*")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createRoom(@ModelAttribute CreateRoomRequestDto requestDto) {
        return roomService.createRoom(requestDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getRoomById(@PathVariable int id) {
        return roomService.getRoomById(id);
    }

    @GetMapping
    public ResponseEntity<?> getRooms(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) String hotelName,
            @RequestParam(required = false) Boolean available,
            @RequestParam(required = false) String search
    ) {
        return roomService.getRooms(page, size, sortBy, direction, hotelName, available, search);
    }

    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> updateRoom(@PathVariable int id, @ModelAttribute UpdateRoomRequestDto requestDto) {
        return roomService.updateRoom(id, requestDto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteRoom(
            @PathVariable int id

    ) {
        return roomService.deleteRoom(id);
    }

    @GetMapping("/photos/{filename:.+}")
    public ResponseEntity<Resource> getRoomPhoto(@PathVariable String filename) {
        return roomService.getRoomPhoto(filename);
    }
}
