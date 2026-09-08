package com.roommate.hub.repository;

import com.roommate.hub.entity.MatchRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface MatchRequestRepository extends JpaRepository<MatchRequest, Long> {
    Optional<MatchRequest> findBySenderIdAndReceiverId(Long senderId, Long receiverId);
    List<MatchRequest> findByReceiverId(Long receiverId);
    List<MatchRequest> findBySenderId(Long senderId);
}