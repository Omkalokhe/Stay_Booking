package com.repository;

import com.entity.Booking;
import com.enums.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Integer>, JpaSpecificationExecutor<Booking> {

    @Query("""
            select count(b) > 0
            from Booking b
            where b.room.id = :roomId
              and b.bookingStatus in :activeStatuses
              and b.checkInDate < :checkOutDate
              and b.checkOutDate > :checkInDate
            """)
    boolean existsOverlappingBooking(
            @Param("roomId") int roomId,
            @Param("checkInDate") LocalDate checkInDate,
            @Param("checkOutDate") LocalDate checkOutDate,
            @Param("activeStatuses") Collection<BookingStatus> activeStatuses
    );

    @Query("""
            select count(b) > 0
            from Booking b
            where b.room.id = :roomId
              and b.id <> :bookingId
              and b.bookingStatus in :activeStatuses
              and b.checkInDate < :checkOutDate
              and b.checkOutDate > :checkInDate
            """)
    boolean existsOverlappingBookingExcludingCurrent(
            @Param("roomId") int roomId,
            @Param("bookingId") int bookingId,
            @Param("checkInDate") LocalDate checkInDate,
            @Param("checkOutDate") LocalDate checkOutDate,
            @Param("activeStatuses") Collection<BookingStatus> activeStatuses
    );
}

