package com.dto;

import com.enums.Role;
import com.enums.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {

    private int id;
    private String fname;
    private String lname;
    private String email;
    private String mobileno;
    private String gender;
    private String address;
    private String city;
    private String state;
    private String country;
    private String pincode;
    private Role role;
    private UserStatus status;
    private String createdat;
    private String updatedat;
    private String createdby;
    private String updatedby;
}
