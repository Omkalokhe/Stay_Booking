package com.dto;

import com.enums.Role;
import com.enums.UserStatus;
import lombok.Data;

@Data
public class UpdateUserRequestDto {
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
    private String updatedby;
    private String updatedat;
}
