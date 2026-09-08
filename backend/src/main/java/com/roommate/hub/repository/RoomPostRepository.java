package com.roommate.hub.repository;

import com.roommate.hub.entity.RoomPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomPostRepository extends JpaRepository<RoomPost, Long> {
    List<RoomPost> findByStatus(RoomPost.PostStatus status);
    List<RoomPost> findByStatusIn(List<RoomPost.PostStatus> statuses);
}