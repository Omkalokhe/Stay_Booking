package com.serviceImpl;

import com.dto.AdminUpdateRoomStatusRequestDto;
import com.dto.AdminUpdateUserAccessRequestDto;
import com.dto.HotelResponseDto;
import com.dto.PageResponseDto;
import com.dto.RoomResponseDto;
import com.dto.UserDto;
import com.entity.Hotel;
import com.entity.Room;
import com.entity.User;
import com.enums.Role;
import com.enums.UserStatus;
import com.repository.HotelRepository;
import com.repository.RoomRepository;
import com.repository.UserRepository;
import com.service.AdminService;
import com.service.RoomPhotoStorageService;
import org.springframework.beans.BeanUtils;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class AdminServiceImpl implements AdminService {

    private static final String SYSTEM_ADMIN = "SYSTEM_ADMIN";

    private final UserRepository userRepository;
    private final HotelRepository hotelRepository;
    private final RoomRepository roomRepository;
    private final RoomPhotoStorageService roomPhotoStorageService;

    public AdminServiceImpl(UserRepository userRepository,
                            HotelRepository hotelRepository,
                            RoomRepository roomRepository,
                            RoomPhotoStorageService roomPhotoStorageService) {
        this.userRepository = userRepository;
        this.hotelRepository = hotelRepository;
        this.roomRepository = roomRepository;
        this.roomPhotoStorageService = roomPhotoStorageService;
    }

    @Override
    public ResponseEntity<?> getUsers(int page, int size, String sortBy, String direction, Role role, UserStatus status, String search) {
        Pageable pageable = buildPageable(page, size, normalizeUserSortBy(sortBy), direction);
        Specification<User> specification = buildUserSpecification(role, status, search);
        Page<User> userPage = userRepository.findAll(specification, pageable);

        PageResponseDto<UserDto> response = PageResponseDto.<UserDto>builder()
                .content(userPage.getContent().stream().map(this::toUserDto).toList())
                .page(userPage.getNumber())
                .size(userPage.getSize())
                .totalElements(userPage.getTotalElements())
                .totalPages(userPage.getTotalPages())
                .first(userPage.isFirst())
                .last(userPage.isLast())
                .build();

        return ResponseEntity.ok(response);
    }

    @Override
    @Transactional
    public ResponseEntity<?> updateUserAccess(int userId, AdminUpdateUserAccessRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (requestDto.getRole() == null && requestDto.getStatus() == null) {
            return ResponseEntity.badRequest().body("At least one of role or status is required");
        }

        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + userId);
        }

        User user = optionalUser.get();
        if (requestDto.getRole() != null) {
            user.setRole(requestDto.getRole());
        }
        if (requestDto.getStatus() != null) {
            user.setStatus(requestDto.getStatus());
        }
        user.setUpdatedby(isBlank(requestDto.getUpdatedBy()) ? SYSTEM_ADMIN : requestDto.getUpdatedBy().trim());

        User saved = userRepository.save(user);
        return ResponseEntity.ok(toUserDto(saved));
    }

    @Override
    @Transactional
    public ResponseEntity<?> deleteUser(int userId, boolean hardDelete, String deletedBy) {
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + userId);
        }

        User user = optionalUser.get();
        if (hardDelete) {
            userRepository.delete(user);
            return ResponseEntity.noContent().build();
        }

        if (user.getStatus() == UserStatus.DELETED) {
            return ResponseEntity.ok("User is already deleted");
        }

        user.setStatus(UserStatus.DELETED);
        user.setUpdatedby(isBlank(deletedBy) ? SYSTEM_ADMIN : deletedBy.trim());
        userRepository.save(user);
        return ResponseEntity.ok("User deleted successfully");
    }

    @Override
    public ResponseEntity<?> getHotels(int page, int size, String sortBy, String direction, String city, String country, String search) {
        Pageable pageable = buildPageable(page, size, normalizeHotelSortBy(sortBy), direction);

        Page<Hotel> hotelPage = hotelRepository.findByCityIgnoreCaseContainingAndCountryIgnoreCaseContainingAndNameIgnoreCaseContaining(
                normalizeFilter(city),
                normalizeFilter(country),
                normalizeFilter(search),
                pageable
        );

        PageResponseDto<HotelResponseDto> response = PageResponseDto.<HotelResponseDto>builder()
                .content(hotelPage.getContent().stream().map(this::toHotelResponse).toList())
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
    public ResponseEntity<?> deleteHotel(int hotelId, String deletedBy) {
        Optional<Hotel> optionalHotel = hotelRepository.findById(hotelId);
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + hotelId);
        }

        Hotel hotel = optionalHotel.get();
        if (!isBlank(deletedBy)) {
            hotel.setUpdatedby(deletedBy.trim());
        } else if (isBlank(hotel.getUpdatedby())) {
            hotel.setUpdatedby(SYSTEM_ADMIN);
        }

        List<String> roomPhotos = hotel.getRooms().stream()
                .flatMap(room -> room.getPhotoPaths().stream())
                .toList();

        hotelRepository.delete(hotel);
        roomPhotoStorageService.deleteRoomPhotos(roomPhotos);
        return ResponseEntity.noContent().build();
    }

    @Override
    public ResponseEntity<?> getRooms(int page, int size, String sortBy, String direction, String hotelName, Boolean available, String search) {
        Pageable pageable = buildPageable(page, size, normalizeRoomSortBy(sortBy), direction);
        Specification<Room> specification = buildRoomSpecification(hotelName, available, search);
        Page<Room> roomPage = roomRepository.findAll(specification, pageable);

        PageResponseDto<RoomResponseDto> response = PageResponseDto.<RoomResponseDto>builder()
                .content(roomPage.getContent().stream().map(this::toRoomResponse).toList())
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
    public ResponseEntity<?> updateRoomStatus(int roomId, AdminUpdateRoomStatusRequestDto requestDto) {
        if (requestDto == null || requestDto.getAvailable() == null) {
            return ResponseEntity.badRequest().body("available is required");
        }

        Optional<Room> optionalRoom = roomRepository.findById(roomId);
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + roomId);
        }

        Room room = optionalRoom.get();
        room.setAvailable(requestDto.getAvailable());
        room.setUpdatedby(isBlank(requestDto.getUpdatedBy()) ? SYSTEM_ADMIN : requestDto.getUpdatedBy().trim());
        Room updated = roomRepository.save(room);

        return ResponseEntity.ok(toRoomResponse(updated));
    }

    @Override
    @Transactional
    public ResponseEntity<?> deleteRoom(int roomId) {
        Optional<Room> optionalRoom = roomRepository.findById(roomId);
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + roomId);
        }

        Room room = optionalRoom.get();
        List<String> photoNames = new ArrayList<>(room.getPhotoPaths());
        roomRepository.delete(room);
        roomPhotoStorageService.deleteRoomPhotos(photoNames);
        return ResponseEntity.noContent().build();
    }

    private Pageable buildPageable(int page, int size, String sortBy, String direction) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 100));
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC;
        return PageRequest.of(safePage, safeSize, Sort.by(sortDirection, sortBy));
    }

    private Specification<User> buildUserSpecification(Role role, UserStatus status, String search) {
        return (root, query, cb) -> {
            List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();

            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (!isBlank(search)) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(
                        cb.or(
                                cb.like(cb.lower(root.get("fname")), pattern),
                                cb.like(cb.lower(root.get("lname")), pattern),
                                cb.like(cb.lower(root.get("email")), pattern)
                        )
                );
            }
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
    }

    private Specification<Room> buildRoomSpecification(String hotelName, Boolean available, String search) {
        return (root, query, cb) -> {
            List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();

            if (!isBlank(hotelName)) {
                predicates.add(cb.like(cb.lower(root.get("hotel").get("name")), "%" + hotelName.trim().toLowerCase() + "%"));
            }
            if (available != null) {
                predicates.add(cb.equal(root.get("available"), available));
            }
            if (!isBlank(search)) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(
                        cb.or(
                                cb.like(cb.lower(root.get("roomType")), pattern),
                                cb.like(cb.lower(root.get("description")), pattern),
                                cb.like(cb.lower(root.get("hotel").get("name")), pattern)
                        )
                );
            }
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
    }

    private UserDto toUserDto(User user) {
        UserDto dto = new UserDto();
        BeanUtils.copyProperties(user, dto);
        return dto;
    }

    private HotelResponseDto toHotelResponse(Hotel hotel) {
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

    private RoomResponseDto toRoomResponse(Room room) {
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

    private String normalizeUserSortBy(String sortBy) {
        if (isBlank(sortBy)) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "id", "fname", "lname", "email", "role", "status", "createdat", "updatedat" -> sortBy.trim();
            default -> "id";
        };
    }

    private String normalizeHotelSortBy(String sortBy) {
        if (isBlank(sortBy)) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "id", "name", "city", "country", "rating", "createdat", "updatedat" -> sortBy.trim();
            default -> "id";
        };
    }

    private String normalizeRoomSortBy(String sortBy) {
        if (isBlank(sortBy)) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "id", "roomType", "price", "available", "createdat", "updatedat" -> sortBy.trim();
            case "hotelName" -> "hotel.name";
            default -> "id";
        };
    }

    private String normalizeFilter(String value) {
        return isBlank(value) ? "" : value.trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}

