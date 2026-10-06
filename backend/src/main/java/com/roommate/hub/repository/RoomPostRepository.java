package com.roommate.hub.repository;

import com.roommate.hub.entity.RoomPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoomPostRepository extends JpaRepository<RoomPost, Long> {
    // Validate the read version at commit even for an unchanged moderation decision.
    @Lock(LockModeType.OPTIMISTIC)
    @Query("SELECT p FROM RoomPost p WHERE p.id = :id")
    Optional<RoomPost> findByIdForModeration(@Param("id") Long id);

    List<RoomPost> findByStatus(RoomPost.PostStatus status);
    List<RoomPost> findByStatusInAndAuthorStatus(List<RoomPost.PostStatus> statuses, String authorStatus);
    Optional<RoomPost> findByIdAndStatusInAndAuthorStatus(Long id, List<RoomPost.PostStatus> statuses, String authorStatus);
    List<RoomPost> findByAuthorId(Long authorId);
}
