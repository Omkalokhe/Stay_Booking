package com.serviceImpl;

import com.dto.LoginRequestDto;
import com.dto.LoginResponseDto;
import com.dto.UserDto;
import com.entity.User;
import com.enums.UserStatus;
import com.repository.UserRepository;
import com.service.LoginService;
import org.springframework.beans.BeanUtils;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class LoginServiceImpl implements LoginService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public LoginServiceImpl(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public ResponseEntity<?> login(LoginRequestDto loginRequestDto) {
        if (loginRequestDto == null
                || isBlank(loginRequestDto.getEmail())
                || isBlank(loginRequestDto.getPassword())
                || loginRequestDto.getRole() == null) {
            return ResponseEntity.badRequest().body("Email, password and role are required");
        }

        User user = userRepository.findByEmailIgnoreCase(loginRequestDto.getEmail().trim());
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid email or password");
        }

        if (user.getStatus() != UserStatus.ACTIVE) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Account is not active");
        }

        if (user.getRole() != loginRequestDto.getRole()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Invalid role for this account");
        }

        boolean validPassword = passwordEncoder.matches(loginRequestDto.getPassword(), user.getPassword());

        // Backward compatibility if old users were saved with plain text password.
        if (!validPassword && loginRequestDto.getPassword().equals(user.getPassword())) {
            validPassword = true;
            user.setPassword(passwordEncoder.encode(loginRequestDto.getPassword()));
            userRepository.save(user);
        }

        if (!validPassword) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid email or password");
        }

        UserDto userDto = new UserDto();
        BeanUtils.copyProperties(user, userDto);

        LoginResponseDto response = LoginResponseDto.builder()
                .message("Login successful")
                .user(userDto)
                .build();
        return ResponseEntity.ok(response);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
