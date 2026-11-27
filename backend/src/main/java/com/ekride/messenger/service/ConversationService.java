package com.ekride.messenger.service;

import com.ekride.messenger.dto.*;
import com.ekride.messenger.model.*;
import com.ekride.messenger.repository.ConversationParticipantRepository;
import com.ekride.messenger.repository.ConversationRepository;
import com.ekride.messenger.repository.MessageRepository;
import com.ekride.rides.Ride;
import com.ekride.rides.RideRepository;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final RideRepository rideRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ConversationService(
            ConversationRepository conversationRepository,
            ConversationParticipantRepository participantRepository,
            MessageRepository messageRepository,
            RideRepository rideRepository,
            UserRepository userRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.conversationRepository = conversationRepository;
        this.participantRepository = participantRepository;
        this.messageRepository = messageRepository;
        this.rideRepository = rideRepository;
        this.userRepository = userRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional(readOnly = true)
    public List<ConversationSummaryDto> getConversationsForUser(Long userId) {
        List<Conversation> conversations = conversationRepository.findConversationsForUser(userId);
        List<ConversationSummaryDto> result = new ArrayList<>();

        for (Conversation c : conversations) {
            ConversationSummaryDto summary = buildSummary(c, userId);
            result.add(summary);
        }
        return result;
    }

    @Transactional
    public ConversationSummaryDto getConversationByRideId(Long rideId, Long userId) {
        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new IllegalArgumentException("Ride not found: " + rideId));

        Conversation conversation = conversationRepository.findByRideId(rideId)
                .orElseGet(() -> createConversationForRideInternal(ride));

        // Strict Match-Gating: user must be creator, driver, or active participant
        boolean isCreator = ride.getCreatorId().equals(userId);
        boolean isDriver = ride.getDriverId() != null && ride.getDriverId().equals(userId);
        Optional<ConversationParticipant> existingPart = participantRepository.findByConversationIdAndUserId(conversation.getId(), userId);

        if (!isCreator && !isDriver && existingPart.isEmpty()) {
            throw new AccessDeniedException("You are not a participant in this ride's conversation");
        }

        if (existingPart.isEmpty() && (isCreator || isDriver)) {
            ConversationParticipant cp = new ConversationParticipant(conversation.getId(), userId, ParticipantRole.PROVIDER);
            participantRepository.save(cp);
        }

        return buildSummary(conversation, userId);
    }

    @Transactional(readOnly = true)
    public List<MessageDto> getMessages(Long conversationId, Long userId, int page, int size) {
        ConversationParticipant participant = participantRepository.findByConversationIdAndUserId(conversationId, userId)
                .orElseThrow(() -> new AccessDeniedException("Access denied: You are not a participant in this conversation"));

        PageRequest pageRequest = PageRequest.of(Math.max(0, page), Math.max(1, Math.min(100, size)));
        Page<Message> messagePage;

        if (participant.getLeftAt() != null) {
            // Can only view messages up to the point when they left
            messagePage = messageRepository.findMessagesWithCutoff(conversationId, participant.getLeftAt(), pageRequest);
        } else {
            messagePage = messageRepository.findByConversationIdOrderByCreatedAtDesc(conversationId, pageRequest);
        }

        List<Message> messages = new ArrayList<>(messagePage.getContent());
        Collections.reverse(messages); // Return chronological order (oldest -> newest)

        // Preload sender names to avoid N+1
        Map<Long, User> userCache = new HashMap<>();
        Map<Long, ParticipantRole> roleCache = new HashMap<>();
        List<ConversationParticipant> allParts = participantRepository.findByConversationId(conversationId);
        for (ConversationParticipant cp : allParts) {
            roleCache.put(cp.getUserId(), cp.getRole());
            userRepository.findById(cp.getUserId()).ifPresent(u -> userCache.put(u.getId(), u));
        }

        List<MessageDto> dtoList = new ArrayList<>();
        for (Message m : messages) {
            String senderName = null;
            ParticipantRole senderRole = null;
            if (m.getSenderId() != null) {
                User u = userCache.get(m.getSenderId());
                senderName = u != null ? u.getFullName() : "Student #" + m.getSenderId();
                senderRole = roleCache.get(m.getSenderId());
            }
            dtoList.add(MessageDto.fromEntity(m, senderName, senderRole));
        }
        return dtoList;
    }

    @Transactional
    public MessageDto sendMessage(Long conversationId, Long userId, SendMessageRequest request) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found: " + conversationId));

        ConversationParticipant participant = participantRepository.findByConversationIdAndUserId(conversationId, userId)
                .orElseThrow(() -> new AccessDeniedException("Access denied: You are not a participant in this conversation"));

        if (!participant.isActive()) {
            throw new AccessDeniedException("You have left this ride and can no longer send messages");
        }

        User sender = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        Message message = new Message(conversationId, userId, MessageType.TEXT, request.getContent().trim());
        Message saved = messageRepository.save(message);

        conversation.setLastMessageAt(saved.getCreatedAt());
        conversation.setUpdatedAt(saved.getCreatedAt());
        conversationRepository.save(conversation);

        // Update sender's read pointer
        participant.setLastReadMessageId(saved.getId());
        participant.setLastReadAt(saved.getCreatedAt());
        participantRepository.save(participant);

        MessageDto dto = MessageDto.fromEntity(saved, sender.getFullName(), participant.getRole());

        // Broadcast to STOMP channel
        messagingTemplate.convertAndSend("/topic/conversations/" + conversationId, dto);

        return dto;
    }

    @Transactional
    public void markAsRead(Long conversationId, Long userId) {
        ConversationParticipant participant = participantRepository.findByConversationIdAndUserId(conversationId, userId)
                .orElseThrow(() -> new AccessDeniedException("You are not a participant in this conversation"));

        Optional<Message> latest = messageRepository.findTopByConversationIdOrderByCreatedAtDesc(conversationId);
        latest.ifPresent(message -> {
            participant.setLastReadMessageId(message.getId());
            participant.setLastReadAt(Instant.now());
            participantRepository.save(participant);
        });
    }

    // --- Lifecycle Hooks ---

    @Transactional
    public Conversation createConversationForRide(Ride ride) {
        return conversationRepository.findByRideId(ride.getId())
                .orElseGet(() -> createConversationForRideInternal(ride));
    }

    private Conversation createConversationForRideInternal(Ride ride) {
        int seats = ride.getTotalSeats() != null ? ride.getTotalSeats() : 4;
        ConversationType initialType = (seats <= 2) ? ConversationType.DIRECT : ConversationType.DIRECT;

        Conversation conv = new Conversation(ride.getId(), initialType);
        conv = conversationRepository.save(conv);

        // Add creator as PROVIDER
        ConversationParticipant creatorPart = new ConversationParticipant(conv.getId(), ride.getCreatorId(), ParticipantRole.PROVIDER);
        participantRepository.save(creatorPart);

        // Initial system welcome message
        String vehicleLabel = (seats <= 2) ? "Bike" : (seats == 3) ? "CNG Auto / Rickshaw" : "Car";
        Message sysMsg = new Message(conv.getId(), null, MessageType.SYSTEM,
                "Ride created for " + vehicleLabel + ". Commute chat is open for matched campus peers.");
        messageRepository.save(sysMsg);

        return conv;
    }

    @Transactional
    public void addParticipantToRide(Long rideId, Long passengerId) {
        Ride ride = rideRepository.findById(rideId).orElse(null);
        if (ride == null) return;

        Conversation conv = createConversationForRide(ride);
        User passenger = userRepository.findById(passengerId).orElse(null);
        String name = (passenger != null) ? passenger.getFullName() : "Student #" + passengerId;

        Optional<ConversationParticipant> existing = participantRepository.findByConversationIdAndUserId(conv.getId(), passengerId);
        if (existing.isPresent()) {
            ConversationParticipant cp = existing.get();
            cp.setLeftAt(null); // Re-activate
            cp.setJoinedAt(Instant.now());
            participantRepository.save(cp);
        } else {
            ConversationParticipant cp = new ConversationParticipant(conv.getId(), passengerId, ParticipantRole.SEEKER);
            participantRepository.save(cp);
        }

        // Evaluate Dynamic 1-on-1 vs Group Chat Rule:
        long activeCount = participantRepository.countByConversationIdAndLeftAtIsNull(conv.getId());
        int seats = ride.getTotalSeats() != null ? ride.getTotalSeats() : 4;

        if (seats <= 2) {
            // Bike: strictly 1-on-1 (2 people max)
            conv.setType(ConversationType.DIRECT);
        } else if (activeCount >= 3) {
            // 3+ active participants in Rickshaw/CNG or Car/Uber -> Upgrades to GROUP!
            conv.setType(ConversationType.GROUP);
        } else {
            conv.setType(ConversationType.DIRECT);
        }
        conv.setLastMessageAt(Instant.now());
        conv.setUpdatedAt(Instant.now());
        conversationRepository.save(conv);

        // Broadcast System Message
        String vehicleDesc = (seats <= 2) ? "bike ride" : (seats == 3) ? "CNG ride" : "carpool";
        Message sysMsg = new Message(conv.getId(), null, MessageType.SYSTEM, name + " joined the " + vehicleDesc + ".");
        Message savedSysMsg = messageRepository.save(sysMsg);

        MessageDto sysDto = MessageDto.fromEntity(savedSysMsg, null, null);
        messagingTemplate.convertAndSend("/topic/conversations/" + conv.getId(), sysDto);
    }

    @Transactional
    public void removeParticipantFromRide(Long rideId, Long passengerId) {
        Conversation conv = conversationRepository.findByRideId(rideId).orElse(null);
        if (conv == null) return;

        User passenger = userRepository.findById(passengerId).orElse(null);
        String name = (passenger != null) ? passenger.getFullName() : "Student #" + passengerId;

        participantRepository.findByConversationIdAndUserId(conv.getId(), passengerId).ifPresent(cp -> {
            cp.setLeftAt(Instant.now());
            participantRepository.save(cp);
        });

        // Broadcast System Leave Message
        Message sysMsg = new Message(conv.getId(), null, MessageType.SYSTEM, name + " left the ride.");
        Message savedSysMsg = messageRepository.save(sysMsg);

        conv.setLastMessageAt(Instant.now());
        conv.setUpdatedAt(Instant.now());
        conversationRepository.save(conv);

        MessageDto sysDto = MessageDto.fromEntity(savedSysMsg, null, null);
        messagingTemplate.convertAndSend("/topic/conversations/" + conv.getId(), sysDto);
    }

    public boolean isUserActiveParticipant(Long conversationId, Long userId) {
        return participantRepository.existsByConversationIdAndUserIdAndLeftAtIsNull(conversationId, userId);
    }

    // --- Helper to build conversation summary ---

    private ConversationSummaryDto buildSummary(Conversation c, Long currentUserId) {
        ConversationSummaryDto summary = new ConversationSummaryDto();
        summary.setId(c.getId());
        summary.setRideId(c.getRideId());
        summary.setType(c.getType());
        summary.setStatus(c.getStatus());
        summary.setLastMessageAt(c.getLastMessageAt());

        // Ride Context
        rideRepository.findById(c.getRideId()).ifPresent(ride -> {
            summary.setRideContext(RideContextDto.fromRide(ride));
        });

        // Participants
        List<ConversationParticipant> participants = participantRepository.findByConversationId(c.getId());
        List<ParticipantDto> participantDtos = new ArrayList<>();
        ConversationParticipant currentUserPart = null;

        for (ConversationParticipant cp : participants) {
            if (cp.getUserId().equals(currentUserId)) {
                currentUserPart = cp;
            }
            User u = userRepository.findById(cp.getUserId()).orElse(null);
            participantDtos.add(ParticipantDto.fromEntity(cp, u));
        }
        summary.setParticipants(participantDtos);

        // Unread Count
        if (currentUserPart != null) {
            Long lastReadId = currentUserPart.getLastReadMessageId();
            if (lastReadId == null) {
                summary.setUnreadCount(messageRepository.countByConversationId(c.getId()));
            } else {
                summary.setUnreadCount(messageRepository.countUnreadMessages(c.getId(), lastReadId));
            }
        }

        // Last Message
        messageRepository.findTopByConversationIdOrderByCreatedAtDesc(c.getId()).ifPresent(lastMsg -> {
            String senderName = null;
            ParticipantRole senderRole = null;
            if (lastMsg.getSenderId() != null) {
                for (ParticipantDto p : participantDtos) {
                    if (p.getUserId().equals(lastMsg.getSenderId())) {
                        senderName = p.getFullName();
                        senderRole = p.getRole();
                        break;
                    }
                }
            }
            summary.setLastMessage(MessageDto.fromEntity(lastMsg, senderName, senderRole));
        });

        return summary;
    }
}
