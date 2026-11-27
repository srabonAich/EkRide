package com.ekride.messenger.controller;

import com.ekride.common.ApiResponse;
import com.ekride.messenger.dto.ConversationSummaryDto;
import com.ekride.messenger.dto.MessageDto;
import com.ekride.messenger.dto.SendMessageRequest;
import com.ekride.messenger.service.ConversationService;
import com.ekride.security.CustomUserDetails;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/conversations")
public class ChatController {

    private final ConversationService conversationService;

    public ChatController(ConversationService conversationService) {
        this.conversationService = conversationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ConversationSummaryDto>>> getMyConversations(
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        List<ConversationSummaryDto> list = conversationService.getConversationsForUser(userDetails.getId());
        return ResponseEntity.ok(ApiResponse.ok("Conversations loaded", list));
    }

    @GetMapping("/by-ride/{rideId}")
    public ResponseEntity<ApiResponse<ConversationSummaryDto>> getConversationByRide(
            @PathVariable Long rideId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        ConversationSummaryDto dto = conversationService.getConversationByRideId(rideId, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.ok("Conversation loaded", dto));
    }

    @GetMapping("/{conversationId}/messages")
    public ResponseEntity<ApiResponse<List<MessageDto>>> getMessages(
            @PathVariable Long conversationId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "30") int size,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        List<MessageDto> messages = conversationService.getMessages(conversationId, userDetails.getId(), page, size);
        return ResponseEntity.ok(ApiResponse.ok("Messages loaded", messages));
    }

    @PostMapping("/{conversationId}/messages")
    public ResponseEntity<ApiResponse<MessageDto>> sendMessageRest(
            @PathVariable Long conversationId,
            @Valid @RequestBody SendMessageRequest request,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        MessageDto dto = conversationService.sendMessage(conversationId, userDetails.getId(), request);
        return ResponseEntity.ok(ApiResponse.ok("Message sent", dto));
    }

    @PostMapping("/{conversationId}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(
            @PathVariable Long conversationId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        conversationService.markAsRead(conversationId, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.ok("Marked as read", null));
    }

    // --- STOMP WebSocket Handler ---
    @MessageMapping("/chat/{conversationId}/send")
    public void sendMessageStomp(
            @DestinationVariable Long conversationId,
            @Payload SendMessageRequest request,
            Principal principal) {
        if (principal == null) {
            throw new IllegalArgumentException("Unauthenticated WebSocket session");
        }
        Long userId = Long.valueOf(principal.getName());
        conversationService.sendMessage(conversationId, userId, request);
    }
}
