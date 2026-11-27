package com.ekride.messenger.dto;

import com.ekride.messenger.model.Conversation;
import com.ekride.messenger.model.ConversationStatus;
import com.ekride.messenger.model.ConversationType;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class ConversationSummaryDto {
    private Long id;
    private Long rideId;
    private ConversationType type;
    private ConversationStatus status;
    private Instant lastMessageAt;
    private long unreadCount;
    private MessageDto lastMessage;
    private RideContextDto rideContext;
    private List<ParticipantDto> participants = new ArrayList<>();

    public ConversationSummaryDto() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }

    public ConversationType getType() { return type; }
    public void setType(ConversationType type) { this.type = type; }

    public ConversationStatus getStatus() { return status; }
    public void setStatus(ConversationStatus status) { this.status = status; }

    public Instant getLastMessageAt() { return lastMessageAt; }
    public void setLastMessageAt(Instant lastMessageAt) { this.lastMessageAt = lastMessageAt; }

    public long getUnreadCount() { return unreadCount; }
    public void setUnreadCount(long unreadCount) { this.unreadCount = unreadCount; }

    public MessageDto getLastMessage() { return lastMessage; }
    public void setLastMessage(MessageDto lastMessage) { this.lastMessage = lastMessage; }

    public RideContextDto getRideContext() { return rideContext; }
    public void setRideContext(RideContextDto rideContext) { this.rideContext = rideContext; }

    public List<ParticipantDto> getParticipants() { return participants; }
    public void setParticipants(List<ParticipantDto> participants) { this.participants = participants; }
}
