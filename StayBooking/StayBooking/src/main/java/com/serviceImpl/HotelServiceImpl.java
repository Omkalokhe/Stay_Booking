package com.serviceImpl;

import com.dto.CreateHotelRequestDto;
import com.dto.HotelResponseDto;
import com.dto.PageResponseDto;
import com.dto.UpdateHotelRequestDto;
import com.entity.Hotel;
import com.repository.HotelRepository;
import com.service.HotelService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class HotelServiceImpl implements HotelService {

    private final HotelRepository hotelRepository;

    public HotelServiceImpl(HotelRepository hotelRepository) {
        this.hotelRepository = hotelRepository;
    }

    @Override
    public ResponseEntity<?> createHotel(CreateHotelRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (isBlank(requestDto.getName()) || isBlank(requestDto.getCity()) || isBlank(requestDto.getCountry())) {
            return ResponseEntity.badRequest().body("name, city and country are required");
        }
        if (requestDto.getRating() != null && !isValidRating(requestDto.getRating().doubleValue())) {
            return ResponseEntity.badRequest().body("rating must be between 0 and 5");
        }

        Hotel hotel = new Hotel();
        hotel.setName(requestDto.getName().trim());
        hotel.setDescription(trimOrNull(requestDto.getDescription()));
        hotel.setAddress(trimOrNull(requestDto.getAddress()));
        hotel.setCity(requestDto.getCity().trim());
        hotel.setState(trimOrNull(requestDto.getState()));
        hotel.setCountry(requestDto.getCountry().trim());
        hotel.setPincode(trimOrNull(requestDto.getPincode()));
        hotel.setRating(requestDto.getRating());
        hotel.setCreatedby(isBlank(requestDto.getCreatedby()) ? "SYSTEM" : requestDto.getCreatedby().trim());
        hotel.setUpdatedby(hotel.getCreatedby());

        Hotel saved = hotelRepository.save(hotel);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @Override
    public ResponseEntity<?> getHotelById(int id) {
        Optional<Hotel> optionalHotel = hotelRepository.findById(id);
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + id);
        }
        return ResponseEntity.ok(toResponse(optionalHotel.get()));
    }

    @Override
    public ResponseEntity<?> getHotels(int page, int size, String sortBy, String direction, String city, String country, String search) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 100));

        String safeSortBy = normalizeSortBy(sortBy);
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(safePage, safeSize, Sort.by(sortDirection, safeSortBy));

        String safeCity = normalizeFilter(city);
        String safeCountry = normalizeFilter(country);
        String safeSearch = normalizeFilter(search);

        Page<Hotel> hotelPage = hotelRepository
                .findByCityIgnoreCaseContainingAndCountryIgnoreCaseContainingAndNameIgnoreCaseContaining(
                        safeCity, safeCountry, safeSearch, pageable);

        PageResponseDto<HotelResponseDto> response = PageResponseDto.<HotelResponseDto>builder()
                .content(hotelPage.getContent().stream().map(this::toResponse).toList())
                .page(hotelPage.getNumber())
                .size(hotelPage.getSize())
                .totalElements(hotelPage.getTotalElements())
                .totalPages(hotelPage.getTotalPages())
                .first(hotelPage.isFirst())
                .last(hotelPage.isLast())
                .build();

        return ResponseEntity.ok(response);
    }

    @Override
    public ResponseEntity<?> updateHotel(int id, UpdateHotelRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }

        Optional<Hotel> optionalHotel = hotelRepository.findById(id);
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + id);
        }

        Hotel hotel = optionalHotel.get();
        if (requestDto.getName() != null) {
            hotel.setName(trimOrNull(requestDto.getName()));
        }
        if (requestDto.getDescription() != null) {
            hotel.setDescription(trimOrNull(requestDto.getDescription()));
        }
        if (requestDto.getAddress() != null) {
            hotel.setAddress(trimOrNull(requestDto.getAddress()));
        }
        if (requestDto.getCity() != null) {
            hotel.setCity(trimOrNull(requestDto.getCity()));
        }
        if (requestDto.getState() != null) {
            hotel.setState(trimOrNull(requestDto.getState()));
        }
        if (requestDto.getCountry() != null) {
            hotel.setCountry(trimOrNull(requestDto.getCountry()));
        }
        if (requestDto.getPincode() != null) {
            hotel.setPincode(trimOrNull(requestDto.getPincode()));
        }
        if (requestDto.getRating() != null) {
            if (!isValidRating(requestDto.getRating().doubleValue())) {
                return ResponseEntity.badRequest().body("rating must be between 0 and 5");
            }
            hotel.setRating(requestDto.getRating());
        }
        if (!isBlank(requestDto.getUpdatedby())) {
            hotel.setUpdatedby(requestDto.getUpdatedby().trim());
        } else if (isBlank(hotel.getUpdatedby())) {
            hotel.setUpdatedby("SYSTEM");
        }

        Hotel updated = hotelRepository.save(hotel);
        return ResponseEntity.ok(toResponse(updated));
    }

    @Override
    public ResponseEntity<?> deleteHotel(int id, String deletedBy) {
        Optional<Hotel> optionalHotel = hotelRepository.findById(id);
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + id);
        }

        Hotel hotel = optionalHotel.get();
        if (!isBlank(deletedBy)) {
            hotel.setUpdatedby(deletedBy.trim());
            hotelRepository.save(hotel);
        }
        hotelRepository.delete(hotel);
        return ResponseEntity.noContent().build();
    }

    private HotelResponseDto toResponse(Hotel hotel) {
        return HotelResponseDto.builder()
                .id(hotel.getId())
                .name(hotel.getName())
                .description(hotel.getDescription())
                .address(hotel.getAddress())
                .city(hotel.getCity())
                .state(hotel.getState())
                .country(hotel.getCountry())
                .pincode(hotel.getPincode())
                .rating(hotel.getRating())
                .createdat(hotel.getCreatedat())
                .updatedat(hotel.getUpdatedat())
                .createdby(hotel.getCreatedby())
                .updatedby(hotel.getUpdatedby())
                .build();
    }

    private String normalizeSortBy(String sortBy) {
        if (isBlank(sortBy)) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "name", "city", "country", "rating", "createdat" -> sortBy.trim();
            default -> "id";
        };
    }

    private String normalizeFilter(String value) {
        return isBlank(value) ? "" : value.trim();
    }

    private String trimOrNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isValidRating(double rating) {
        return rating >= 0.0 && rating <= 5.0;
    }
}
