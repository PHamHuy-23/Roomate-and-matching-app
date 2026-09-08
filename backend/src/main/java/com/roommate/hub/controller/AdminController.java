package com.roommate.hub.controller;

import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/posts")
    public ResponseEntity<List<RoomPost>> getAllPosts() {
        return ResponseEntity.ok(adminService.getAllPostsForModeration());
    }

    @PutMapping("/posts/{postId}/moderate")
    public ResponseEntity<RoomPost> moderatePost(
            @PathVariable Long postId,
            @RequestParam String status) {
        return ResponseEntity.ok(adminService.moderatePost(postId, status));
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    @PutMapping("/users/{userId}/toggle-status")
    public ResponseEntity<Map<String, Object>> toggleUserStatus(@PathVariable Long userId) {
        return ResponseEntity.ok(adminService.toggleUserStatus(userId));
    }
}