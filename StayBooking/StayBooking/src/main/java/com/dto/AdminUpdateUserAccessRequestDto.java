package com.dto;

import com.enums.Role;
import com.enums.UserStatus;
import lombok.Data;

@Data
public class AdminUpdateUserAccessRequestDto {
    private Role role;
    private UserStatus status;
    private String updatedBy;
}

