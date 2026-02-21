package com.serviceImpl;

import com.dto.BookingResponseDto;
import com.dto.CreateBookingRequestDto;
import com.dto.PageResponseDto;
import com.dto.UpdateBookingRequestDto;
import com.dto.UpdateBookingStatusRequestDto;
import com.entity.Booking;
import com.entity.Hotel;
import com.entity.Room;
import com.entity.User;
import com.enums.BookingStatus;
import com.enums.PaymentStatus;
import com.repository.BookingRepository;
import com.repository.HotelRepository;
import com.repository.RoomRepository;
import com.repository.UserRepository;
import com.service.BookingService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;

@Service
public class BookingServiceImpl implements BookingService {

    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final HotelRepository hotelRepository;
    private final RoomRepository roomRepository;

    public BookingServiceImpl(BookingRepository bookingRepository,
                              UserRepository userRepository,
                              HotelRepository hotelRepository,
                              RoomRepository roomRepository) {
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
        this.hotelRepository = hotelRepository;
        this.roomRepository = roomRepository;
    }

    @Override
    @Transactional
    public ResponseEntity<?> createBooking(CreateBookingRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (requestDto.getUserId() == null || requestDto.getHotelId() == null || requestDto.getRoomId() == null) {
            return ResponseEntity.badRequest().body("userId, hotelId and roomId are required");
        }
        if (requestDto.getNumberOfGuests() == null || requestDto.getNumberOfGuests() <= 0) {
            return ResponseEntity.badRequest().body("numberOfGuests must be greater than 0");
        }

        LocalDate checkInDate = requestDto.getCheckInDate();
        LocalDate checkOutDate = requestDto.getCheckOutDate();
        String dateValidationError = validateDates(checkInDate, checkOutDate);
        if (dateValidationError != null) {
            return ResponseEntity.badRequest().body(dateValidationError);
        }

        Optional<User> optionalUser = userRepository.findById(requestDto.getUserId());
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + requestDto.getUserId());
        }
        Optional<Hotel> optionalHotel = hotelRepository.findById(requestDto.getHotelId());
        if (optionalHotel.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Hotel not found with id: " + requestDto.getHotelId());
        }
        Optional<Room> optionalRoom = roomRepository.findById(requestDto.getRoomId());
        if (optionalRoom.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Room not found with id: " + requestDto.getRoomId());
        }

        User user = optionalUser.get();
        Hotel hotel = optionalHotel.get();
        Room room = optionalRoom.get();

        if (room.getHotel().getId() != hotel.getId()) {
            return ResponseEntity.badRequest().body("Room does not belong to the provided hotel");
        }
        if (!room.isAvailable()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Room is marked unavailable");
        }

        if (bookingRepository.existsOverlappingBooking(
                room.getId(),
                checkInDate,
                checkOutDate,
                activeBlockingStatuses()
        )) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Room is already booked for the selected date range");
        }

        long nights = ChronoUnit.DAYS.between(checkInDate, checkOutDate);
        BigDecimal totalAmount = room.getPrice().multiply(BigDecimal.valueOf(nights));

        Booking booking = new Booking();
        booking.setUser(user);
        booking.setHotel(hotel);
        booking.setRoom(room);
        booking.setCheckInDate(checkInDate);
        booking.setCheckOutDate(checkOutDate);
        booking.setNumberOfGuests(requestDto.getNumberOfGuests());
        booking.setTotalAmount(totalAmount);
        booking.setBookingStatus(BookingStatus.PENDING);
        booking.setPaymentStatus(PaymentStatus.PENDING);

        Booking saved = bookingRepository.save(booking);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @Override
    public ResponseEntity<?> getBookingById(int id) {
        Optional<Booking> optionalBooking = bookingRepository.findById(id);
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Booking not found with id: " + id);
        }
        return ResponseEntity.ok(toResponse(optionalBooking.get()));
    }

    @Override
    public ResponseEntity<?> getBookings(int page, int size, String sortBy, String direction, Integer userId, Integer hotelId,
                                         Integer roomId, BookingStatus bookingStatus, PaymentStatus paymentStatus,
                                         LocalDate checkInFrom, LocalDate checkOutTo) {
        Pageable pageable = buildPageable(page, size, normalizeSortBy(sortBy), direction);
        Specification<Booking> specification = buildSpecification(
                userId, hotelId, roomId, bookingStatus, paymentStatus, checkInFrom, checkOutTo
        );

        Page<Booking> bookingPage = bookingRepository.findAll(specification, pageable);
        PageResponseDto<BookingResponseDto> response = PageResponseDto.<BookingResponseDto>builder()
                .content(bookingPage.getContent().stream().map(this::toResponse).toList())
                .page(bookingPage.getNumber())
                .size(bookingPage.getSize())
                .totalElements(bookingPage.getTotalElements())
                .totalPages(bookingPage.getTotalPages())
                .first(bookingPage.isFirst())
                .last(bookingPage.isLast())
                .build();
        return ResponseEntity.ok(response);
    }

    @Override
    @Transactional
    public ResponseEntity<?> updateBooking(int id, UpdateBookingRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }

        Optional<Booking> optionalBooking = bookingRepository.findById(id);
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Booking not found with id: " + id);
        }

        Booking booking = optionalBooking.get();
        if (isTerminalStatus(booking.getBookingStatus())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Cannot update a cancelled/completed/no-show booking");
        }

        LocalDate nextCheckIn = requestDto.getCheckInDate() != null ? requestDto.getCheckInDate() : booking.getCheckInDate();
        LocalDate nextCheckOut = requestDto.getCheckOutDate() != null ? requestDto.getCheckOutDate() : booking.getCheckOutDate();
        String dateValidationError = validateDates(nextCheckIn, nextCheckOut);
        if (dateValidationError != null) {
            return ResponseEntity.badRequest().body(dateValidationError);
        }

        if (requestDto.getNumberOfGuests() != null && requestDto.getNumberOfGuests() <= 0) {
            return ResponseEntity.badRequest().body("numberOfGuests must be greater than 0");
        }

        if (bookingRepository.existsOverlappingBookingExcludingCurrent(
                booking.getRoom().getId(),
                booking.getId(),
                nextCheckIn,
                nextCheckOut,
                activeBlockingStatuses()
        )) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Room is already booked for the selected date range");
        }

        booking.setCheckInDate(nextCheckIn);
        booking.setCheckOutDate(nextCheckOut);
        if (requestDto.getNumberOfGuests() != null) {
            booking.setNumberOfGuests(requestDto.getNumberOfGuests());
        }

        long nights = ChronoUnit.DAYS.between(nextCheckIn, nextCheckOut);
        booking.setTotalAmount(booking.getRoom().getPrice().multiply(BigDecimal.valueOf(nights)));

        Booking updated = bookingRepository.save(booking);
        return ResponseEntity.ok(toResponse(updated));
    }

    @Override
    @Transactional
    public ResponseEntity<?> updateBookingStatus(int id, UpdateBookingStatusRequestDto requestDto) {
        if (requestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }
        if (requestDto.getBookingStatus() == null && requestDto.getPaymentStatus() == null) {
            return ResponseEntity.badRequest().body("At least one of bookingStatus or paymentStatus is required");
        }

        Optional<Booking> optionalBooking = bookingRepository.findById(id);
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Booking not found with id: " + id);
        }

        Booking booking = optionalBooking.get();
        if (requestDto.getPaymentStatus() != null) {
            booking.setPaymentStatus(requestDto.getPaymentStatus());
            if (requestDto.getPaymentStatus() == PaymentStatus.SUCCESS && booking.getBookingStatus() == BookingStatus.PENDING) {
                booking.setBookingStatus(BookingStatus.CONFIRMED);
            }
            if (requestDto.getPaymentStatus() == PaymentStatus.REFUNDED && booking.getBookingStatus() == BookingStatus.CONFIRMED) {
                booking.setBookingStatus(BookingStatus.CANCELLED);
            }
        }
        if (requestDto.getBookingStatus() != null) {
            BookingStatus nextStatus = requestDto.getBookingStatus();
            if (!isValidStatusTransition(booking.getBookingStatus(), nextStatus)) {
                return ResponseEntity.badRequest().body(
                        "Invalid booking status transition: " + booking.getBookingStatus() + " -> " + nextStatus
                );
            }
            booking.setBookingStatus(nextStatus);
        }

        Booking updated = bookingRepository.save(booking);
        return ResponseEntity.ok(toResponse(updated));
    }


    @Override
    @Transactional
    public ResponseEntity<?> cancelBooking(int id) {
        Optional<Booking> optionalBooking = bookingRepository.findById(id);
        if (optionalBooking.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Booking not found with id: " + id);
        }

        Booking booking = optionalBooking.get();
        if (booking.getBookingStatus() == BookingStatus.CANCELLED) {
            return ResponseEntity.ok("Booking is already cancelled");
        }
        if (booking.getBookingStatus() == BookingStatus.COMPLETED || booking.getBookingStatus() == BookingStatus.NO_SHOW) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Cannot cancel a completed/no-show booking");
        }

        booking.setBookingStatus(BookingStatus.CANCELLED);
        if (booking.getPaymentStatus() == PaymentStatus.SUCCESS) {
            booking.setPaymentStatus(PaymentStatus.REFUNDED);
        }

        Booking updated = bookingRepository.save(booking);
        return ResponseEntity.ok(toResponse(updated));
    }

    private Specification<Booking> buildSpecification(Integer userId, Integer hotelId, Integer roomId,
                                                      BookingStatus bookingStatus, PaymentStatus paymentStatus,
                                                      LocalDate checkInFrom, LocalDate checkOutTo) {
        return (root, query, cb) -> {
            List<jakarta.persistence.criteria.Predicate> predicates = new java.util.ArrayList<>();

            if (userId != null) {
                predicates.add(cb.equal(root.get("user").get("id"), userId));
            }
            if (hotelId != null) {
                predicates.add(cb.equal(root.get("hotel").get("id"), hotelId));
            }
            if (roomId != null) {
                predicates.add(cb.equal(root.get("room").get("id"), roomId));
            }
            if (bookingStatus != null) {
                predicates.add(cb.equal(root.get("bookingStatus"), bookingStatus));
            }
            if (paymentStatus != null) {
                predicates.add(cb.equal(root.get("paymentStatus"), paymentStatus));
            }
            if (checkInFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("checkInDate"), checkInFrom));
            }
            if (checkOutTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("checkOutDate"), checkOutTo));
            }

            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
    }

    private Pageable buildPageable(int page, int size, String sortBy, String direction) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 100));
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC;
        return PageRequest.of(safePage, safeSize, Sort.by(sortDirection, sortBy));
    }

    private String normalizeSortBy(String sortBy) {
        if (sortBy == null || sortBy.trim().isEmpty()) {
            return "id";
        }
        return switch (sortBy.trim()) {
            case "id", "checkInDate", "checkOutDate", "totalAmount", "bookingStatus", "paymentStatus", "createdAt", "updatedAt" -> sortBy.trim();
            default -> "id";
        };
    }

    private String validateDates(LocalDate checkInDate, LocalDate checkOutDate) {
        if (checkInDate == null || checkOutDate == null) {
            return "checkInDate and checkOutDate are required";
        }
        if (checkInDate.isBefore(LocalDate.now())) {
            return "checkInDate cannot be in the past";
        }
        if (!checkOutDate.isAfter(checkInDate)) {
            return "checkOutDate must be after checkInDate";
        }
        return null;
    }

    private EnumSet<BookingStatus> activeBlockingStatuses() {
        return EnumSet.of(BookingStatus.PENDING, BookingStatus.CONFIRMED);
    }

    private boolean isTerminalStatus(BookingStatus status) {
        return status == BookingStatus.CANCELLED || status == BookingStatus.COMPLETED || status == BookingStatus.NO_SHOW;
    }

    private boolean isValidStatusTransition(BookingStatus current, BookingStatus next) {
        if (current == next) {
            return true;
        }
        return switch (current) {
            case PENDING -> next == BookingStatus.CONFIRMED || next == BookingStatus.CANCELLED;
            case CONFIRMED -> next == BookingStatus.COMPLETED || next == BookingStatus.CANCELLED || next == BookingStatus.NO_SHOW;
            case CANCELLED, COMPLETED, NO_SHOW -> false;
        };
    }

    private BookingResponseDto toResponse(Booking booking) {
        return BookingResponseDto.builder()
                .id(booking.getId())
                .userId(booking.getUser().getId())
                .userEmail(booking.getUser().getEmail())
                .hotelId(booking.getHotel().getId())
                .hotelName(booking.getHotel().getName())
                .roomId(booking.getRoom().getId())
                .roomType(booking.getRoom().getRoomType())
                .checkInDate(booking.getCheckInDate())
                .checkOutDate(booking.getCheckOutDate())
                .numberOfGuests(booking.getNumberOfGuests())
                .totalAmount(booking.getTotalAmount())
                .bookingStatus(booking.getBookingStatus())
                .paymentStatus(booking.getPaymentStatus())
                .paymentMethod(booking.getPaymentMethod())
                .paymentReference(booking.getPaymentReference())
                .createdAt(booking.getCreatedAt())
                .updatedAt(booking.getUpdatedAt())
                .build();
    }

}
