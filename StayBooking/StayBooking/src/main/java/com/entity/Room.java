package com.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "rooms", indexes = {
        @Index(name = "idx_room_hotel_id", columnList = "hotel_id"),
        @Index(name = "idx_room_type", columnList = "room_type"),
        @Index(name = "idx_room_available", columnList = "is_available")
})
@Data
@NoArgsConstructor
public class Room {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_id", nullable = false)
    @JsonBackReference
    private Hotel hotel;

    @Column(name = "room_type", nullable = false, length = 80)
    private String roomType;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "is_available")
    private boolean available;

    @ElementCollection
    @CollectionTable(name = "room_photos", joinColumns = @JoinColumn(name = "room_id"))
    @Column(name = "photo_path", nullable = false, length = 500)
    private List<String> photoPaths = new ArrayList<>();

    private String createdat;
    private String updatedat;
    private String createdby;
    private String updatedby;

    @PrePersist
    public void prePersist() {
        String now = nowUtc();
        if (isBlank(createdat)) {
            createdat = now;
        }
        if (isBlank(updatedat)) {
            updatedat = now;
        }
        if (isBlank(createdby)) {
            createdby = "SYSTEM";
        }
        if (isBlank(updatedby)) {
            updatedby = createdby;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedat = nowUtc();
        if (isBlank(updatedby)) {
            updatedby = "SYSTEM";
        }
    }

    private String nowUtc() {
        return OffsetDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
