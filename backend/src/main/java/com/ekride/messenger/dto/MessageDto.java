package com.ekride.messenger.dto;

import com.ekride.messenger.model.Message;
import com.ekride.messenger.model.MessageType;
import com.ekride.messenger.model.ParticipantRole;

import java.time.Instant;

public class MessageDto {
    private Long id;
    private Long conversationId;
    private Long senderId;
    private String senderName;
    private ParticipantRole senderRole;
    private MessageType messageType;
    private String content;
    private Instant createdAt;

    public MessageDto() {}

    public static MessageDto fromEntity(Message message, String senderName, ParticipantRole senderRole) {
        MessageDto dto = new MessageDto();
        dto.setId(message.getId());
        dto.setConversationId(message.getConversationId());
        dto.setSenderId(message.getSenderId());
        dto.setSenderName(senderName);
        dto.setSenderRole(senderRole);
        dto.setMessageType(message.getMessageType());
        dto.setContent(message.getContent());
        dto.setCreatedAt(message.getCreatedAt());
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getConversationId() { return conversationId; }
    public void setConversationId(Long conversationId) { this.conversationId = conversationId; }

    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }

    public String getSenderName() { return senderName; }
    public void setSenderName(String senderName) { this.senderName = senderName; }

    public ParticipantRole getSenderRole() { return senderRole; }
    public void setSenderRole(ParticipantRole senderRole) { this.senderRole = senderRole; }

    public MessageType getMessageType() { return messageType; }
    public void setMessageType(MessageType messageType) { this.messageType = messageType; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
