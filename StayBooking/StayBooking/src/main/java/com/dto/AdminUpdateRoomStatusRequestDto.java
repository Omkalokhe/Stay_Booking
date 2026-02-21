package com.dto;

import lombok.Data;

@Data
public class AdminUpdateRoomStatusRequestDto {
    private Boolean available;
    private String updatedBy;
}

