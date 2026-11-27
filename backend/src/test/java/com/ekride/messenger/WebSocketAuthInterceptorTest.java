package com.ekride.messenger;

import com.ekride.messenger.model.ConversationParticipant;
import com.ekride.messenger.repository.ConversationParticipantRepository;
import com.ekride.messenger.security.WebSocketAuthInterceptor;
import com.ekride.security.CustomUserDetails;
import com.ekride.security.CustomUserDetailsService;
import com.ekride.security.JwtService;
import com.ekride.users.Role;
import com.ekride.users.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

class WebSocketAuthInterceptorTest {

    private JwtService jwtService;
    private CustomUserDetailsService userDetailsService;
    private ConversationParticipantRepository participantRepository;
    private WebSocketAuthInterceptor interceptor;

    @BeforeEach
    void setUp() {
        jwtService = Mockito.mock(JwtService.class);
        userDetailsService = Mockito.mock(CustomUserDetailsService.class);
        participantRepository = Mockito.mock(ConversationParticipantRepository.class);
        interceptor = new WebSocketAuthInterceptor(jwtService, userDetailsService, participantRepository);
    }

    @Test
    @DisplayName("STOMP CONNECT authenticates user and sets Principal with valid JWT")
    void testStompConnectAuthentication() {
        String token = "valid-test-token";
        String email = "student@univ.edu";
        Long userId = 42L;

        when(jwtService.extractEmail(token)).thenReturn(email);
        when(jwtService.extractUserId(token)).thenReturn(userId);
        when(jwtService.isTokenValid(token, email)).thenReturn(true);

        User user = new User();
        user.setId(userId);
        user.setEmail(email);
        user.setRole(Role.PASSENGER);
        CustomUserDetails userDetails = new CustomUserDetails(user);
        when(userDetailsService.loadUserByUsername(email)).thenReturn(userDetails);

        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
        accessor.addNativeHeader("Authorization", "Bearer " + token);
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        Message<?> result = interceptor.preSend(message, Mockito.mock(MessageChannel.class));
        assertNotNull(result);

        StompHeaderAccessor resAccessor = StompHeaderAccessor.wrap(result);
        assertNotNull(resAccessor.getUser(), "Principal must be set on valid CONNECT");
        assertEquals("42", resAccessor.getUser().getName());
    }

    @Test
    @DisplayName("STOMP SUBSCRIBE rejects non-participant of conversation with AccessDeniedException")
    void testStompSubscribeRejectsNonParticipant() {
        User user = new User();
        user.setId(99L);
        CustomUserDetails userDetails = new CustomUserDetails(user);
        WebSocketAuthInterceptor.StompPrincipal principal = new WebSocketAuthInterceptor.StompPrincipal("99", userDetails);

        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.SUBSCRIBE);
        accessor.setDestination("/topic/conversations/10");
        accessor.setUser(principal);
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        when(participantRepository.findByConversationIdAndUserId(10L, 99L)).thenReturn(Optional.empty());

        assertThrows(AccessDeniedException.class, () -> {
            interceptor.preSend(message, Mockito.mock(MessageChannel.class));
        });
    }

    @Test
    @DisplayName("STOMP SEND rejects user who has left the ride")
    void testStompSendRejectsInactiveParticipant() {
        User user = new User();
        user.setId(50L);
        CustomUserDetails userDetails = new CustomUserDetails(user);
        WebSocketAuthInterceptor.StompPrincipal principal = new WebSocketAuthInterceptor.StompPrincipal("50", userDetails);

        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.SEND);
        accessor.setDestination("/app/chat/7/send");
        accessor.setUser(principal);
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        when(participantRepository.existsByConversationIdAndUserIdAndLeftAtIsNull(7L, 50L)).thenReturn(false);

        assertThrows(AccessDeniedException.class, () -> {
            interceptor.preSend(message, Mockito.mock(MessageChannel.class));
        });
    }
}
