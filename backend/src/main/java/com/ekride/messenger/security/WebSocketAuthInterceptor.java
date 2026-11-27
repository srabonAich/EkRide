package com.ekride.messenger.security;

import com.ekride.messenger.repository.ConversationParticipantRepository;
import com.ekride.security.CustomUserDetails;
import com.ekride.security.CustomUserDetailsService;
import com.ekride.security.JwtService;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;
    private final ConversationParticipantRepository participantRepository;

    private static final Pattern TOPIC_PATTERN = Pattern.compile("^/topic/conversations/(\\d+)$");
    private static final Pattern SEND_PATTERN = Pattern.compile("^/app/chat/(\\d+)/send$");

    public WebSocketAuthInterceptor(
            JwtService jwtService,
            CustomUserDetailsService userDetailsService,
            ConversationParticipantRepository participantRepository) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
        this.participantRepository = participantRepository;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }

        boolean wasImmutable = !accessor.isMutable();
        if (wasImmutable) {
            accessor = StompHeaderAccessor.wrap(message);
        }

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            authenticateConnect(accessor);
        } else if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            authorizeSubscribe(accessor);
        } else if (StompCommand.SEND.equals(accessor.getCommand())) {
            authorizeSend(accessor);
        }

        if (wasImmutable) {
            return MessageBuilder.createMessage(message.getPayload(), accessor.getMessageHeaders());
        }
        return message;
    }

    private void authenticateConnect(StompHeaderAccessor accessor) {
        String authHeader = accessor.getFirstNativeHeader("Authorization");
        if (authHeader == null || authHeader.isBlank()) {
            authHeader = accessor.getFirstNativeHeader("token");
        }

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            authHeader = authHeader.substring(7);
        }

        if (authHeader != null && !authHeader.isBlank()) {
            try {
                String email = jwtService.extractEmail(authHeader);
                Long userId = jwtService.extractUserId(authHeader);
                if (email != null && userId != null && jwtService.isTokenValid(authHeader, email)) {
                    CustomUserDetails userDetails = (CustomUserDetails) userDetailsService.loadUserByUsername(email);
                    // Use userId as the Principal name for convenient Long.valueOf(principal.getName()) lookup
                    Principal principal = new StompPrincipal(String.valueOf(userId), userDetails);
                    accessor.setUser(principal);
                }
            } catch (Exception e) {
                throw new AccessDeniedException("Invalid JWT token on STOMP CONNECT: " + e.getMessage());
            }
        }
    }

    private void authorizeSubscribe(StompHeaderAccessor accessor) {
        String destination = accessor.getDestination();
        if (destination == null) return;

        Matcher matcher = TOPIC_PATTERN.matcher(destination);
        if (matcher.matches()) {
            Long conversationId = Long.parseLong(matcher.group(1));
            Principal user = accessor.getUser();
            if (user == null) {
                throw new AccessDeniedException("Unauthorized: Authentication required to subscribe to conversation");
            }
            Long userId = Long.parseLong(user.getName());
            boolean isParticipant = participantRepository.findByConversationIdAndUserId(conversationId, userId).isPresent();
            if (!isParticipant) {
                throw new AccessDeniedException("Access denied: You are not a matched participant of conversation " + conversationId);
            }
        }
    }

    private void authorizeSend(StompHeaderAccessor accessor) {
        String destination = accessor.getDestination();
        if (destination == null) return;

        Matcher matcher = SEND_PATTERN.matcher(destination);
        if (matcher.matches()) {
            Long conversationId = Long.parseLong(matcher.group(1));
            Principal user = accessor.getUser();
            if (user == null) {
                throw new AccessDeniedException("Unauthorized: Authentication required to send message");
            }
            Long userId = Long.parseLong(user.getName());
            boolean isActive = participantRepository.existsByConversationIdAndUserIdAndLeftAtIsNull(conversationId, userId);
            if (!isActive) {
                throw new AccessDeniedException("Access denied: You are not an active participant of conversation " + conversationId);
            }
        }
    }

    public static class StompPrincipal extends UsernamePasswordAuthenticationToken implements Principal {
        private final String name;

        public StompPrincipal(String name, CustomUserDetails userDetails) {
            super(userDetails, null, userDetails.getAuthorities());
            this.name = name;
        }

        @Override
        public String getName() {
            return name;
        }
    }
}
