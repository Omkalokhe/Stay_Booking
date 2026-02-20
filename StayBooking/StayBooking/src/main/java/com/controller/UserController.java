package com.controller;

import com.dto.UpdateUserRequestDto;
import com.entity.User;
import com.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*") // allow Flutter requests
public class UserController {
    @Autowired
    private UserService userService;

    @PostMapping(value = "/register")
    public ResponseEntity<?> registerUser(@RequestBody User user) {
        return userService.registerUser(user);
    }

    @GetMapping(value = "getById/{id}")
    public ResponseEntity<?> getUserById(@PathVariable("id")int id) {
        return userService.getUserById(id);
    }

    @GetMapping(value = "/getAll")
    public ResponseEntity<?> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping(value = "getByEmail/{email}")
    public ResponseEntity<?> getUserByEmail(@PathVariable("email")String email) {
        return userService.getUserByEmail(email);
    }

    @PutMapping(value = "/update/{id}")
    public ResponseEntity<?> updateUser(@PathVariable("id") int id,
                                        @RequestBody UpdateUserRequestDto updateUserRequestDto) {
        return userService.updateUser(id, updateUserRequestDto);
    }

    @DeleteMapping(value = "/delete/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable("id") int id
                                        ) {
        return userService.deleteUser(id);
    }
}
