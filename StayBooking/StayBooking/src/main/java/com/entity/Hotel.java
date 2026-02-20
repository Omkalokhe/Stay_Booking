package com.entity;

import com.fasterxml.jackson.annotation.JsonManagedReference;
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
@Table(name = "hotels", indexes = {
        @Index(name = "idx_hotel_city", columnList = "city"),
        @Index(name = "idx_hotel_country", columnList = "country"),
        @Index(name = "idx_hotel_name", columnList = "name")
})
@NoArgsConstructor
@Data
public class Hotel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String name;
    private String description;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;

    @Column(precision = 2, scale = 1)
    private BigDecimal rating;

    private String createdat;
    private String updatedat;
    private String createdby;
    private String updatedby;

    @OneToMany(mappedBy = "hotel", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private List<Room> rooms = new ArrayList<>();

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
