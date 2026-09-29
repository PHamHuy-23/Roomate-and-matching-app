package com.roommate.hub.repository;

import com.roommate.hub.entity.MatchRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MatchRequestRepository extends JpaRepository<MatchRequest, Long> {
    Optional<MatchRequest> findBySenderIdAndReceiverId(Long senderId, Long receiverId);
    List<MatchRequest> findByReceiverId(Long receiverId);
    List<MatchRequest> findBySenderId(Long senderId);

    @Query("SELECT m FROM MatchRequest m WHERE (m.sender.id = :u1 AND m.receiver.id = :u2) OR (m.sender.id = :u2 AND m.receiver.id = :u1)")
    Optional<MatchRequest> findConnectionBetweenUsers(@Param("u1") Long u1, @Param("u2") Long u2);
}