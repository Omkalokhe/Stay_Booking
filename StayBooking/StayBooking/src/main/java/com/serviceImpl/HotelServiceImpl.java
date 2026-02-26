package com.serviceImpl;

import com.dto.CreateHotelRequestDto;
import com.dto.HotelResponseDto;
import com.dto.PageResponseDto;
import com.dto.UpdateHotelRequestDto;
import com.entity.Hotel;
import com.repository.HotelRepository;
import com.service.HotelPhotoStorageService;
import com.service.HotelService;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class HotelServiceImpl implements HotelService {

    private final HotelRepository hotelRepository;
    private final HotelPhotoStorageService hotelPhotoStorageService;

    public HotelServiceImpl(HotelRepository hotelRepository, HotelPhotoStorageService hotelPhotoStorageService) {
        this.hotelRepository = hotelRepository;
        this.hotelPhotoStorageService = hotelPhotoStorageService;
    }

    @Override
    @Transactional
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

        List<String> savedPhotos;
        try {
            savedPhotos = hotelPhotoStorageService.saveHotelPhotos(requestDto.getPhotos());
            hotel.setPhotoPaths(new ArrayList<>(savedPhotos));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(exception.getMessage());
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to save hotel photos");
        }

        try {
            Hotel saved = hotelRepository.save(hotel);
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
        } catch (RuntimeException exception) {
            hotelPhotoStorageService.deleteHotelPhotos(savedPhotos);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to create hotel");
        }
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
    @Transactional
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

        List<String> oldPhotos = new ArrayList<>(hotel.getPhotoPaths());
        List<MultipartFile> incomingPhotos = requestDto.getPhotos();
        boolean hasIncomingPhotos = incomingPhotos != null && incomingPhotos.stream().anyMatch(file -> file != null && !file.isEmpty());
        boolean replacePhotos = Boolean.TRUE.equals(requestDto.getReplacePhotos());
        List<String> newlySavedPhotos = new ArrayList<>();

        try {
            if (replacePhotos) {
                newlySavedPhotos = hasIncomingPhotos
                        ? hotelPhotoStorageService.saveHotelPhotos(incomingPhotos)
                        : List.of();
                hotel.setPhotoPaths(new ArrayList<>(newlySavedPhotos));
            } else if (hasIncomingPhotos) {
                newlySavedPhotos = hotelPhotoStorageService.saveHotelPhotos(incomingPhotos);
                List<String> allPhotos = new ArrayList<>(hotel.getPhotoPaths());
                allPhotos.addAll(newlySavedPhotos);
                hotel.setPhotoPaths(allPhotos);
            }
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(exception.getMessage());
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to save hotel photos");
        }

        try {
            Hotel updated = hotelRepository.save(hotel);
            if (replacePhotos) {
                hotelPhotoStorageService.deleteHotelPhotos(oldPhotos);
            }
            return ResponseEntity.ok(toResponse(updated));
        } catch (RuntimeException exception) {
            hotelPhotoStorageService.deleteHotelPhotos(newlySavedPhotos);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to update hotel");
        }
    }

    @Override
    @Transactional
    public ResponseEntity<?> deleteHotel(int id, String deletedBy) {
        Optional<Hotel> optionalHotel = hotelRepository.findById(id);
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + id);
        }

        Hotel hotel = optionalHotel.get();
        List<String> photoNames = new ArrayList<>(hotel.getPhotoPaths());

        if (!isBlank(deletedBy)) {
            hotel.setUpdatedby(deletedBy.trim());
            hotelRepository.save(hotel);
        }

        try {
            hotelRepository.delete(hotel);
            hotelPhotoStorageService.deleteHotelPhotos(photoNames);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to delete hotel");
        }
    }

    @Override
    public ResponseEntity<Resource> getHotelPhoto(String filename) {
        try {
            Resource resource = hotelPhotoStorageService.loadHotelPhoto(filename);
            MediaType mediaType = resolveMediaType(filename);
            return ResponseEntity.ok().contentType(mediaType).body(resource);
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.notFound().build();
        }
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
                .photoUrls(hotel.getPhotoPaths().stream().map(hotelPhotoStorageService::toPhotoUrl).toList())
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

    private MediaType resolveMediaType(String filename) {
        if (filename == null) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }

        String lowerFilename = filename.toLowerCase();
        if (lowerFilename.endsWith(".png")) {
            return MediaType.IMAGE_PNG;
        }
        if (lowerFilename.endsWith(".webp")) {
            return MediaType.parseMediaType("image/webp");
        }
        if (lowerFilename.endsWith(".gif")) {
            return MediaType.IMAGE_GIF;
        }
        return MediaType.IMAGE_JPEG;
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
