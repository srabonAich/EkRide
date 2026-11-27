package com.ekride.messenger.repository;

import com.ekride.messenger.model.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    Page<Message> findByConversationIdOrderByCreatedAtDesc(Long conversationId, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :convId AND (:cutoff IS NULL OR m.createdAt <= :cutoff) " +
           "ORDER BY m.createdAt DESC")
    Page<Message> findMessagesWithCutoff(
            @Param("convId") Long convId,
            @Param("cutoff") Instant cutoff,
            Pageable pageable);

    Optional<Message> findTopByConversationIdOrderByCreatedAtDesc(Long conversationId);

    @Query("SELECT COUNT(m) FROM Message m WHERE m.conversationId = :convId AND m.id > :lastReadId")
    long countUnreadMessages(@Param("convId") Long convId, @Param("lastReadId") Long lastReadId);

    long countByConversationId(Long convId);
}
