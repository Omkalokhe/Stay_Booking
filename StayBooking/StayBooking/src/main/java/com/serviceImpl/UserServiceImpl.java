package com.serviceImpl;

import com.dto.UpdateUserRequestDto;
import com.dto.UserDto;
import com.entity.User;
import com.enums.Role;
import com.enums.UserStatus;
import com.repository.UserRepository;
import com.service.UserService;
import org.springframework.beans.BeanUtils;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public ResponseEntity<?> registerUser(User user) {
        if (user == null || isBlank(user.getEmail()) || isBlank(user.getPassword())) {
            return ResponseEntity.badRequest().body("Email and password are required");
        }

        if (userRepository.findByEmailIgnoreCase(user.getEmail().trim()) != null) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("User already exists with this email");
        }

        user.setEmail(user.getEmail().trim().toLowerCase());
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        if (isBlank(user.getCreatedby())) {
            user.setCreatedby(user.getEmail());
        }
        if (isBlank(user.getUpdatedby())) {
            user.setUpdatedby(user.getCreatedby());
        }
        if (user.getRole() == null) {
            user.setRole(Role.CUSTOMER);
        }
        if (user.getStatus() == null) {
            user.setStatus(UserStatus.ACTIVE);
        }

        userRepository.save(user);
        return ResponseEntity.ok("User registered successfully");
    }

    @Override
    public ResponseEntity<?> getUserById(int id) {
        Optional<User> optionalUser = userRepository.findById(id);
        if (optionalUser.isPresent()) {
            return ResponseEntity.ok(toUserDto(optionalUser.get()));
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + id);
    }

    @Override
    public ResponseEntity<?> getAllUsers() {
        List<User> userList = userRepository.findAll();
        List<UserDto> userDtoList = userList.stream().map(this::toUserDto).toList();
        return ResponseEntity.ok(userDtoList);
    }

    @Override
    public ResponseEntity<?> getUserByEmail(String email) {
        if (isBlank(email)) {
            return ResponseEntity.badRequest().body("Email is required");
        }

        User user = userRepository.findByEmailIgnoreCase(email.trim());
        if (user != null) {
            return ResponseEntity.ok(toUserDto(user));
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with email: " + email);
    }

    @Override
    public ResponseEntity<?> updateUser(int id, UpdateUserRequestDto updateUserRequestDto) {
        if (updateUserRequestDto == null) {
            return ResponseEntity.badRequest().body("Request body is required");
        }

        Optional<User> optionalUser = userRepository.findById(id);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + id);
        }

        User existingUser = optionalUser.get();

        String normalizedEmail = null;
        if (!isBlank(updateUserRequestDto.getEmail())) {
            normalizedEmail = updateUserRequestDto.getEmail().trim().toLowerCase();
            User sameEmailUser = userRepository.findByEmailIgnoreCase(normalizedEmail);
            if (sameEmailUser != null && sameEmailUser.getId() != existingUser.getId()) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body("Email already in use by another user");
            }
        }

        if (updateUserRequestDto.getFname() != null) {
            existingUser.setFname(trimOrNull(updateUserRequestDto.getFname()));
        }
        if (updateUserRequestDto.getLname() != null) {
            existingUser.setLname(trimOrNull(updateUserRequestDto.getLname()));
        }
        existingUser.setEmail(normalizedEmail != null ? normalizedEmail : existingUser.getEmail());
        if (updateUserRequestDto.getMobileno() != null) {
            existingUser.setMobileno(trimOrNull(updateUserRequestDto.getMobileno()));
        }
        if (updateUserRequestDto.getGender() != null) {
            existingUser.setGender(trimOrNull(updateUserRequestDto.getGender()));
        }
        if (updateUserRequestDto.getAddress() != null) {
            existingUser.setAddress(trimOrNull(updateUserRequestDto.getAddress()));
        }
        if (updateUserRequestDto.getCity() != null) {
            existingUser.setCity(trimOrNull(updateUserRequestDto.getCity()));
        }
        if (updateUserRequestDto.getState() != null) {
            existingUser.setState(trimOrNull(updateUserRequestDto.getState()));
        }
        if (updateUserRequestDto.getCountry() != null) {
            existingUser.setCountry(trimOrNull(updateUserRequestDto.getCountry()));
        }
        if (updateUserRequestDto.getPincode() != null) {
            existingUser.setPincode(trimOrNull(updateUserRequestDto.getPincode()));
        }

        if (updateUserRequestDto.getRole() != null) {
            existingUser.setRole(updateUserRequestDto.getRole());
        }
        if (updateUserRequestDto.getStatus() != null) {
            existingUser.setStatus(updateUserRequestDto.getStatus());
        }

        existingUser.setUpdatedat(currentUtcTime());
        if (!isBlank(updateUserRequestDto.getUpdatedby())) {
            existingUser.setUpdatedby(updateUserRequestDto.getUpdatedby().trim());
        } else if (isBlank(existingUser.getUpdatedby())) {
            existingUser.setUpdatedby("SYSTEM");
        }

        User updatedUser = userRepository.save(existingUser);
        return ResponseEntity.ok(toUserDto(updatedUser));
    }

    @Override
    public ResponseEntity<?> deleteUser(int id) {
        Optional<User> optionalUser = userRepository.findById(id);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found with id: " + id);
        }

        User user = optionalUser.get();
        if (user.getStatus() == UserStatus.DELETED) {
            return ResponseEntity.ok("User is already deleted");
        }

        user.setStatus(UserStatus.DELETED);
        user.setUpdatedat(currentUtcTime());
//        if (!isBlank(deletedBy)) {
//            user.setUpdatedby(deletedBy.trim());
//        } else if (isBlank(user.getUpdatedby())) {
//            user.setUpdatedby("SYSTEM");
//        }

        userRepository.save(user);
        return ResponseEntity.ok("User deleted successfully");
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trimOrNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private UserDto toUserDto(User user) {
        UserDto userDto = new UserDto();
        BeanUtils.copyProperties(user, userDto);
        return userDto;
    }

    private String currentUtcTime() {
        return OffsetDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }
}
