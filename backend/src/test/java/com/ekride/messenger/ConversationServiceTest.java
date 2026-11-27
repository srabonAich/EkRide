package com.ekride.messenger;

import com.ekride.messenger.dto.MessageDto;
import com.ekride.messenger.dto.SendMessageRequest;
import com.ekride.messenger.model.*;
import com.ekride.messenger.repository.ConversationParticipantRepository;
import com.ekride.messenger.repository.ConversationRepository;
import com.ekride.messenger.repository.MessageRepository;
import com.ekride.messenger.service.ConversationService;
import com.ekride.rides.Ride;
import com.ekride.rides.RideRepository;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ConversationServiceTest {

    private ConversationRepository conversationRepo;
    private ConversationParticipantRepository participantRepo;
    private MessageRepository messageRepo;
    private RideRepository rideRepo;
    private UserRepository userRepo;
    private SimpMessagingTemplate messagingTemplate;
    private ConversationService conversationService;

    @BeforeEach
    void setUp() {
        conversationRepo = Mockito.mock(ConversationRepository.class);
        participantRepo = Mockito.mock(ConversationParticipantRepository.class);
        messageRepo = Mockito.mock(MessageRepository.class);
        rideRepo = Mockito.mock(RideRepository.class);
        userRepo = Mockito.mock(UserRepository.class);
        messagingTemplate = Mockito.mock(SimpMessagingTemplate.class);

        conversationService = new ConversationService(
                conversationRepo,
                participantRepo,
                messageRepo,
                rideRepo,
                userRepo,
                messagingTemplate
        );
    }

    @Test
    @DisplayName("2-person Bike ride creates a DIRECT conversation and stays DIRECT")
    void testBikeRideCreatesDirectConversation() {
        Ride bikeRide = new Ride();
        bikeRide.setId(101L);
        bikeRide.setCreatorId(1L);
        bikeRide.setTotalSeats(2); // Bike capacity

        when(conversationRepo.findByRideId(101L)).thenReturn(Optional.empty());
        when(conversationRepo.save(any(Conversation.class))).thenAnswer(i -> {
            Conversation c = i.getArgument(0);
            c.setId(1L);
            return c;
        });
        when(rideRepo.findById(101L)).thenReturn(Optional.of(bikeRide));

        Conversation conv = conversationService.createConversationForRide(bikeRide);
        assertNotNull(conv);
        assertEquals(ConversationType.DIRECT, conv.getType(), "Bike conversation must be DIRECT");

        // Passenger 2 joins
        User p2 = new User();
        p2.setId(2L);
        p2.setFullName("Sadia Islam");
        when(userRepo.findById(2L)).thenReturn(Optional.of(p2));
        when(conversationRepo.findByRideId(101L)).thenReturn(Optional.of(conv));
        when(participantRepo.countByConversationIdAndLeftAtIsNull(1L)).thenReturn(2L);
        when(messageRepo.save(any(Message.class))).thenAnswer(i -> i.getArgument(0));

        conversationService.addParticipantToRide(101L, 2L);

        assertEquals(ConversationType.DIRECT, conv.getType(), "Bike conversation must remain DIRECT with 2 riders");
        verify(messagingTemplate, atLeastOnce()).convertAndSend(eq("/topic/conversations/1"), any(MessageDto.class));
    }

    @Test
    @DisplayName("3-person CNG/Uber dynamically upgrades to GROUP when 3rd student joins and emits system message")
    void testCngUpgradesToGroupWhenThirdParticipantJoins() {
        Ride cngRide = new Ride();
        cngRide.setId(202L);
        cngRide.setCreatorId(1L);
        cngRide.setTotalSeats(3); // CNG capacity

        Conversation conv = new Conversation(202L, ConversationType.DIRECT);
        conv.setId(5L);

        when(rideRepo.findById(202L)).thenReturn(Optional.of(cngRide));
        when(conversationRepo.findByRideId(202L)).thenReturn(Optional.of(conv));
        when(messageRepo.save(any(Message.class))).thenAnswer(i -> {
            Message m = i.getArgument(0);
            m.setId(99L);
            return m;
        });

        // 3rd passenger joins
        User p3 = new User();
        p3.setId(3L);
        p3.setFullName("Kazi Farhan");
        when(userRepo.findById(3L)).thenReturn(Optional.of(p3));
        when(participantRepo.countByConversationIdAndLeftAtIsNull(5L)).thenReturn(3L);

        conversationService.addParticipantToRide(202L, 3L);

        assertEquals(ConversationType.GROUP, conv.getType(), "CNG conversation must upgrade to GROUP when 3 riders join");

        ArgumentCaptor<Message> messageCaptor = ArgumentCaptor.forClass(Message.class);
        verify(messageRepo, atLeastOnce()).save(messageCaptor.capture());

        Message savedMsg = messageCaptor.getValue();
        assertEquals(MessageType.SYSTEM, savedMsg.getMessageType(), "System message must be emitted on join");
        assertTrue(savedMsg.getContent().contains("Kazi Farhan joined the CNG ride"));
    }

    @Test
    @DisplayName("Non-participant gets 403 AccessDeniedException on getMessages and sendMessage")
    void testNonParticipantAccessDenied() {
        Long convId = 10L;
        Long outsiderId = 999L;

        when(participantRepo.findByConversationIdAndUserId(convId, outsiderId)).thenReturn(Optional.empty());

        assertThrows(AccessDeniedException.class, () -> {
            conversationService.getMessages(convId, outsiderId, 0, 30);
        });

        SendMessageRequest req = new SendMessageRequest("Hello?");
        when(conversationRepo.findById(convId)).thenReturn(Optional.of(new Conversation()));

        assertThrows(AccessDeniedException.class, () -> {
            conversationService.sendMessage(convId, outsiderId, req);
        });
    }

    @Test
    @DisplayName("User who left ride cannot send new messages")
    void testLeftParticipantCannotSendMessage() {
        Long convId = 15L;
        Long leaverId = 4L;

        Conversation conv = new Conversation();
        conv.setId(convId);
        when(conversationRepo.findById(convId)).thenReturn(Optional.of(conv));

        ConversationParticipant cp = new ConversationParticipant(convId, leaverId, ParticipantRole.SEEKER);
        cp.setLeftAt(Instant.now()); // Left!
        when(participantRepo.findByConversationIdAndUserId(convId, leaverId)).thenReturn(Optional.of(cp));

        SendMessageRequest req = new SendMessageRequest("Still here?");
        assertThrows(AccessDeniedException.class, () -> {
            conversationService.sendMessage(convId, leaverId, req);
        });
    }
}
