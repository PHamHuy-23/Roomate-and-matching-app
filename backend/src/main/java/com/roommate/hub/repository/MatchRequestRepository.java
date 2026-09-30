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

    @Query("SELECT m FROM MatchRequest m WHERE (m.sender.id = :u1 AND m.receiver.id = :u2) OR (m.sender.id = :u2 AND m.receiver.id = :u1) ORDER BY m.id DESC")
    List<MatchRequest> findAllBetweenUsers(@Param("u1") Long u1, @Param("u2") Long u2);

    default Optional<MatchRequest> findConnectionBetweenUsers(Long u1, Long u2) {
        List<MatchRequest> requests = findAllBetweenUsers(u1, u2);
        return requests.stream().filter(r -> r.getStatus() == MatchRequest.MatchStatus.ACCEPTED)
                .findFirst().or(() -> requests.stream().findFirst());
    }

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT m FROM MatchRequest m WHERE m.id = :id")
    Optional<MatchRequest> findByIdForUpdate(@Param("id") Long id);
}
