package com.dto;

import com.enums.Role;
import lombok.Data;

@Data
public class LoginRequestDto {
    private String email;
    private String password;
    private Role role;
}
