package com.service;

import com.dto.UpdateUserRequestDto;
import com.entity.User;
import org.springframework.http.ResponseEntity;

public interface UserService {

    ResponseEntity<?> registerUser(User user);

    ResponseEntity<?> getUserById(int id);

    ResponseEntity<?> getAllUsers();

    ResponseEntity<?> getUserByEmail(String email);

    ResponseEntity<?> updateUser(int id, UpdateUserRequestDto updateUserRequestDto);

    ResponseEntity<?> deleteUser(int id);
}
