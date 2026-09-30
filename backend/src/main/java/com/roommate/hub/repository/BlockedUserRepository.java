package com.roommate.hub.repository;

import com.roommate.hub.entity.BlockedUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BlockedUserRepository extends JpaRepository<BlockedUser, Long> {
    List<BlockedUser> findByUserId(Long userId);
    List<BlockedUser> findByBlockedUserId(Long blockedUserId);
    Optional<BlockedUser> findByUserIdAndBlockedUserId(Long userId, Long blockedUserId);
    boolean existsByUserIdAndBlockedUserId(Long userId, Long blockedUserId);
    void deleteByUserIdAndBlockedUserId(Long userId, Long blockedUserId);
}
