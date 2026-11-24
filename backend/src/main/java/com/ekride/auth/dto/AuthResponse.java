package com.ekride.auth.dto;

import com.ekride.users.Role;
import java.math.BigDecimal;

public class AuthResponse {
    private String token;
    private Long id;
    private String email;
    private String fullName;
    private String phone;
    private String university;
    private String studentId;
    private Role role;
    private BigDecimal rating;

    public AuthResponse(String token, Long id, String email, String fullName, String phone, String university, String studentId, Role role, BigDecimal rating) {
        this.token = token;
        this.id = id;
        this.email = email;
        this.fullName = fullName;
        this.phone = phone;
        this.university = university;
        this.studentId = studentId;
        this.role = role;
        this.rating = rating;
    }

    public String getToken() { return token; }
    public Long getId() { return id; }
    public String getEmail() { return email; }
    public String getFullName() { return fullName; }
    public String getPhone() { return phone; }
    public String getUniversity() { return university; }
    public String getStudentId() { return studentId; }
    public Role getRole() { return role; }
    public BigDecimal getRating() { return rating; }
}
