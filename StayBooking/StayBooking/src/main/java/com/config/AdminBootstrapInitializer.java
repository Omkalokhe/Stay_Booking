package com.config;

import com.entity.User;
import com.enums.Role;
import com.enums.UserStatus;
import com.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

@Component
public class AdminBootstrapInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrapInitializer.class);
    private static final String SYSTEM_BOOTSTRAP = "SYSTEM_BOOTSTRAP";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminBootstrapProperties properties;

    public AdminBootstrapInitializer(UserRepository userRepository,
                                     PasswordEncoder passwordEncoder,
                                     AdminBootstrapProperties properties) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.properties = properties;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!properties.isEnabled()) {
            return;
        }

        String email = properties.getEmail().trim().toLowerCase();
        User existingUser = userRepository.findByEmailIgnoreCase(email);

        if (existingUser != null) {
            if (existingUser.getRole() != Role.ADMIN) {
                existingUser.setRole(Role.ADMIN);
                existingUser.setUpdatedby(SYSTEM_BOOTSTRAP);
                userRepository.save(existingUser);
                log.info("Existing user promoted to ADMIN for email={}", email);
            }
            return;
        }

        User admin = User.builder()
                .fname(properties.getFirstName())
                .lname(properties.getLastName())
                .email(email)
                .password(passwordEncoder.encode(properties.getPassword()))
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .createdby(SYSTEM_BOOTSTRAP)
                .updatedby(SYSTEM_BOOTSTRAP)
                .build();

        userRepository.save(admin);
        log.info("Default admin user created for email={}", email);
    }
}
