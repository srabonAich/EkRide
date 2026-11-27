package com.ekride.messenger.repository;

import com.ekride.messenger.model.ConversationParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationParticipantRepository extends JpaRepository<ConversationParticipant, Long> {
    Optional<ConversationParticipant> findByConversationIdAndUserId(Long conversationId, Long userId);

    List<ConversationParticipant> findByConversationId(Long conversationId);

    List<ConversationParticipant> findByConversationIdAndLeftAtIsNull(Long conversationId);

    List<ConversationParticipant> findByUserIdAndLeftAtIsNull(Long userId);

    boolean existsByConversationIdAndUserIdAndLeftAtIsNull(Long conversationId, Long userId);

    long countByConversationIdAndLeftAtIsNull(Long conversationId);
}
