package com.ekride.messenger.repository;

import com.ekride.messenger.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    Optional<Conversation> findByRideId(Long rideId);

    @Query("SELECT c FROM Conversation c JOIN ConversationParticipant cp ON c.id = cp.conversationId " +
           "WHERE cp.userId = :userId AND (cp.leftAt IS NULL OR c.updatedAt > cp.leftAt) " +
           "ORDER BY c.lastMessageAt DESC")
    List<Conversation> findConversationsForUser(@Param("userId") Long userId);
}
