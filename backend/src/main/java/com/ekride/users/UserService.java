package com.ekride.users;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User getById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found with id: " + id));
    }

    public User getByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));
    }

    @Transactional
    public User updateProfile(Long userId, String fullName, String phone, String university, String studentId) {
        User user = getById(userId);
        if (fullName != null && !fullName.trim().isEmpty()) user.setFullName(fullName.trim());
        if (phone != null) user.setPhone(phone.trim());
        if (university != null) user.setUniversity(university.trim());
        if (studentId != null) user.setStudentId(studentId.trim());
        return userRepository.save(user);
    }

    @Transactional
    public User switchRole(Long userId, Role newRole) {
        User user = getById(userId);
        user.setRole(newRole);
        return userRepository.save(user);
    }
}
