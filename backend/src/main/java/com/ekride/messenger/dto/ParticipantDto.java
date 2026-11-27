package com.ekride.messenger.dto;

import com.ekride.messenger.model.ConversationParticipant;
import com.ekride.messenger.model.ParticipantRole;
import com.ekride.users.User;

import java.time.Instant;

public class ParticipantDto {
    private Long userId;
    private String fullName;
    private String university;
    private String studentId;
    private ParticipantRole role;
    private Instant joinedAt;
    private Instant leftAt;
    private boolean active;

    public ParticipantDto() {}

    public static ParticipantDto fromEntity(ConversationParticipant cp, User user) {
        ParticipantDto dto = new ParticipantDto();
        dto.setUserId(cp.getUserId());
        dto.setRole(cp.getRole());
        dto.setJoinedAt(cp.getJoinedAt());
        dto.setLeftAt(cp.getLeftAt());
        dto.setActive(cp.isActive());
        if (user != null) {
            dto.setFullName(user.getFullName());
            dto.setUniversity(user.getUniversity());
            dto.setStudentId(user.getStudentId());
        } else {
            dto.setFullName("Student #" + cp.getUserId());
        }
        return dto;
    }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getUniversity() { return university; }
    public void setUniversity(String university) { this.university = university; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public ParticipantRole getRole() { return role; }
    public void setRole(ParticipantRole role) { this.role = role; }

    public Instant getJoinedAt() { return joinedAt; }
    public void setJoinedAt(Instant joinedAt) { this.joinedAt = joinedAt; }

    public Instant getLeftAt() { return leftAt; }
    public void setLeftAt(Instant leftAt) { this.leftAt = leftAt; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
