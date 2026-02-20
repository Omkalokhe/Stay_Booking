package com.entity;

import com.enums.Role;
import com.enums.UserStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String fname;
    private String lname;
    private String email;
    private String password;
    private String mobileno;
    private String gender;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;
    @Enumerated(EnumType.STRING)
    private Role role;
    @Enumerated(EnumType.STRING)
    private UserStatus status;
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
