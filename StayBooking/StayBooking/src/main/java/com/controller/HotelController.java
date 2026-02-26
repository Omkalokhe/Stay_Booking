package com.controller;

import com.dto.CreateHotelRequestDto;
import com.dto.UpdateHotelRequestDto;
import com.service.HotelService;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/hotels")
@CrossOrigin(origins = "*")
public class HotelController {

    private final HotelService hotelService;

    public HotelController(HotelService hotelService) {
        this.hotelService = hotelService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createHotel(@ModelAttribute CreateHotelRequestDto requestDto) {
        return hotelService.createHotel(requestDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getHotelById(@PathVariable int id) {
        return hotelService.getHotelById(id);
    }

    @GetMapping
    public ResponseEntity<?> getHotels(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String search
    ) {
        return hotelService.getHotels(page, size, sortBy, direction, city, country, search);
    }

    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> updateHotel(@PathVariable int id, @ModelAttribute UpdateHotelRequestDto requestDto) {
        return hotelService.updateHotel(id, requestDto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteHotel(
            @PathVariable int id,
            @RequestParam(value = "deletedBy", required = false) String deletedBy
    ) {
        return hotelService.deleteHotel(id, deletedBy);
    }

    @GetMapping("/photos/{filename:.+}")
    public ResponseEntity<Resource> getHotelPhoto(@PathVariable String filename) {
        return hotelService.getHotelPhoto(filename);
    }
}
