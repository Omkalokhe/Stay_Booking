package com.serviceImpl;

import com.dto.CreateRoomRequestDto;
import com.dto.PageResponseDto;
import com.dto.RoomResponseDto;
import com.dto.UpdateRoomRequestDto;
import com.entity.Hotel;
import com.entity.Room;
import com.repository.HotelRepository;
import com.repository.RoomRepository;
import com.service.RoomPhotoStorageService;
import com.service.RoomService;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class RoomServiceImpl implements RoomService {

    private final RoomRepository roomRepository;
    private final HotelRepository hotelRepository;
    private final RoomPhotoStorageService roomPhotoStorageService;

    public RoomServiceImpl(
            RoomRepository roomRepository,
            HotelRepository hotelRepository,
            RoomPhotoStorageService roomPhotoStorageService
    ) {
        this.roomRepository = roomRepository;
        this.hotelRepository = hotelRepository;
        this.roomPhotoStorageService = roomPhotoStorageService;
    }

    @Override
    @Transactional
    public ResponseEntity<?> createRoom(CreateRoomRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (requestDto.getHotelId() == null && isBlank(requestDto.getHotelName())) {
            return ResponseEntity.badRequest().body("Either hotelId or hotelName is required");
        }
        if (isBlank(requestDto.getRoomType())) {
            return ResponseEntity.badRequest().body("roomType is required");
        }
        if (!isValidPrice(requestDto.getPrice())) {
            return ResponseEntity.badRequest().body("price must be greater than 0");
        }

        Hotel resolvedHotel;
        try {
            resolvedHotel = resolveHotel(requestDto.getHotelId(), requestDto.getHotelName());
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(exception.getMessage());
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(exception.getMessage());
        }

        Room room = new Room();
        room.setHotel(resolvedHotel);
        room.setRoomType(requestDto.getRoomType().trim());
        room.setDescription(trimOrNull(requestDto.getDescription()));
        room.setPrice(requestDto.getPrice());
        room.setAvailable(requestDto.getAvailable() == null || requestDto.getAvailable());
        room.setCreatedby(isBlank(requestDto.getCreatedby()) ? "SYSTEM" : requestDto.getCreatedby().trim());
        room.setUpdatedby(room.getCreatedby());

        try {
            List<String> savedPhotos = roomPhotoStorageService.saveRoomPhotos(requestDto.getPhotos());
            room.setPhotoPaths(new ArrayList<>(savedPhotos));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(exception.getMessage());
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to save room photos");
        }

        Room saved = roomRepository.save(room);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @Override
    public ResponseEntity<?> getRoomById(int id) {
        Optional<Room> optionalRoom = roomRepository.findById(id);
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + id);
        }
        return ResponseEntity.ok(toResponse(optionalRoom.get()));
    }

    @Override
    public ResponseEntity<?> getRooms(int page, int size, String sortBy, String direction, String hotelName, Boolean available, String search) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 100));

        String safeSortBy = normalizeSortBy(sortBy);
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(safePage, safeSize, Sort.by(sortDirection, safeSortBy));

        Specification<Room> specification = buildSpecification(hotelName, available, search);
        Page<Room> roomPage = roomRepository.findAll(specification, pageable);

        PageResponseDto<RoomResponseDto> response = PageResponseDto.<RoomResponseDto>builder()
                .content(roomPage.getContent().stream().map(this::toResponse).toList())
                .page(roomPage.getNumber())
                .size(roomPage.getSize())
                .totalElements(roomPage.getTotalElements())
                .totalPages(roomPage.getTotalPages())
                .first(roomPage.isFirst())
                .last(roomPage.isLast())
                .build();

        return ResponseEntity.ok(response);
    }

    @Override
    @Transactional
    public ResponseEntity<?> updateRoom(int id, UpdateRoomRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }

        Optional<Room> optionalRoom = roomRepository.findById(id);
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + id);
        }

        Room room = optionalRoom.get();

        if (requestDto.getHotelId() != null || !isBlank(requestDto.getHotelName())) {
            Hotel resolvedHotel;
            try {
                resolvedHotel = resolveHotel(requestDto.getHotelId(), requestDto.getHotelName());
            } catch (IllegalArgumentException exception) {
                return ResponseEntity.badRequest().body(exception.getMessage());
            } catch (IllegalStateException exception) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(exception.getMessage());
            }
            room.setHotel(resolvedHotel);
        }

        if (requestDto.getRoomType() != null) {
            String roomType = trimOrNull(requestDto.getRoomType());
            if (roomType == null) {
                return ResponseEntity.badRequest().body("roomType cannot be blank");
            }
            room.setRoomType(roomType);
        }

        if (requestDto.getDescription() != null) {
            room.setDescription(trimOrNull(requestDto.getDescription()));
        }

        if (requestDto.getPrice() != null) {
            if (!isValidPrice(requestDto.getPrice())) {
                return ResponseEntity.badRequest().body("price must be greater than 0");
            }
            room.setPrice(requestDto.getPrice());
        }

        if (requestDto.getAvailable() != null) {
            room.setAvailable(requestDto.getAvailable());
        }

        if (!isBlank(requestDto.getUpdatedby())) {
            room.setUpdatedby(requestDto.getUpdatedby().trim());
        } else if (isBlank(room.getUpdatedby())) {
            room.setUpdatedby("SYSTEM");
        }

        List<String> oldPhotos = new ArrayList<>(room.getPhotoPaths());
        List<MultipartFile> incomingPhotos = requestDto.getPhotos();
        boolean hasIncomingPhotos = incomingPhotos != null && incomingPhotos.stream().anyMatch(file -> file != null && !file.isEmpty());
        boolean replacePhotos = Boolean.TRUE.equals(requestDto.getReplacePhotos());

        try {
            if (replacePhotos) {
                List<String> newPhotos = hasIncomingPhotos
                        ? roomPhotoStorageService.saveRoomPhotos(incomingPhotos)
                        : List.of();
                room.setPhotoPaths(new ArrayList<>(newPhotos));
            } else if (hasIncomingPhotos) {
                List<String> newPhotos = roomPhotoStorageService.saveRoomPhotos(incomingPhotos);
                List<String> allPhotos = new ArrayList<>(room.getPhotoPaths());
                allPhotos.addAll(newPhotos);
                room.setPhotoPaths(allPhotos);
            }
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(exception.getMessage());
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to save room photos");
        }

        Room updated = roomRepository.save(room);

        if (replacePhotos) {
            roomPhotoStorageService.deleteRoomPhotos(oldPhotos);
        }

        return ResponseEntity.ok(toResponse(updated));
    }

    @Override
    @Transactional
    public ResponseEntity<?> deleteRoom(int id) {
        Optional<Room> optionalRoom = roomRepository.findById(id);
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + id);
        }

        Room room = optionalRoom.get();
        List<String> photoNames = new ArrayList<>(room.getPhotoPaths());


        roomRepository.delete(room);
        roomPhotoStorageService.deleteRoomPhotos(photoNames);
        return ResponseEntity.noContent().build();
    }

    @Override
    public ResponseEntity<Resource> getRoomPhoto(String filename) {
        try {
            Resource resource = roomPhotoStorageService.loadRoomPhoto(filename);
            MediaType mediaType = resolveMediaType(filename);
            return ResponseEntity.ok().contentType(mediaType).body(resource);
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.notFound().build();
        }
    }

    private Specification<Room> buildSpecification(String hotelName, Boolean available, String search) {
        return (root, query, criteriaBuilder) -> {
            List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();

            if (!isBlank(hotelName)) {
                predicates.add(criteriaBuilder.like(
                        criteriaBuilder.lower(root.get("hotel").get("name")),
                        "%" + hotelName.trim().toLowerCase() + "%"
                ));
            }
            if (available != null) {
                predicates.add(criteriaBuilder.equal(root.get("available"), available));
            }
            if (!isBlank(search)) {
                String normalizedSearch = "%" + search.trim().toLowerCase() + "%";
                predicates.add(criteriaBuilder.like(
                        criteriaBuilder.lower(
                                criteriaBuilder.concat(
                                        root.get("roomType"),
                                        criteriaBuilder.concat(" ", root.get("hotel").get("name"))
                                )
                        ),
                        normalizedSearch
                ));
            }

            return criteriaBuilder.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
    }

    private RoomResponseDto toResponse(Room room) {
        return RoomResponseDto.builder()
                .id(room.getId())
                .hotelId(room.getHotel().getId())
                .hotelName(room.getHotel().getName())
                .roomType(room.getRoomType())
                .description(room.getDescription())
                .price(room.getPrice())
                .available(room.isAvailable())
                .photoUrls(room.getPhotoPaths().stream().map(roomPhotoStorageService::toPhotoUrl).toList())
                .createdat(room.getCreatedat())
                .updatedat(room.getUpdatedat())
                .createdby(room.getCreatedby())
                .updatedby(room.getUpdatedby())
                .build();
    }

    private String normalizeSortBy(String sortBy) {
        if (isBlank(sortBy)) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "roomType", "price", "available", "createdat", "updatedat" -> sortBy.trim();
            case "hotelName" -> "hotel.name";
            default -> "id";
        };
    }

    private Hotel resolveHotel(Integer hotelId, String hotelName) {
        if (hotelId != null) {
            return hotelRepository.findById(hotelId)
                    .orElseThrow(() -> new IllegalStateException("Hotel not found with id: " + hotelId));
        }

        String normalizedName = trimOrNull(hotelName);
        if (normalizedName == null) {
            throw new IllegalArgumentException("Either hotelId or hotelName is required");
        }

        List<Hotel> hotels = hotelRepository.findByNameIgnoreCase(normalizedName);
        if (hotels.isEmpty()) {
            throw new IllegalStateException("Hotel not found with name: " + normalizedName);
        }
        if (hotels.size() > 1) {
            throw new IllegalArgumentException("Multiple hotels found with name: " + normalizedName + ". Use hotelId instead");
        }
        return hotels.get(0);
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

    private boolean isValidPrice(BigDecimal price) {
        return price != null && price.compareTo(BigDecimal.ZERO) > 0;
    }
}
