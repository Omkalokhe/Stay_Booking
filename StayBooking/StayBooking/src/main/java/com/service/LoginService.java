package com.service;

import com.dto.LoginRequestDto;
import org.springframework.http.ResponseEntity;

public interface LoginService {
    ResponseEntity<?> login(LoginRequestDto loginRequestDto);
}
