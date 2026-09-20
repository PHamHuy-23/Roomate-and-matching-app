package com.roommate.hub.controller;

import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.dto.AdminPostResponseDTO;
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
    public ResponseEntity<List<AdminPostResponseDTO>> getAllPosts() {
        return ResponseEntity.ok(adminService.getAllPostsForModeration());
    }

    @PutMapping("/posts/{postId}/moderate")
    public ResponseEntity<AdminPostResponseDTO> moderatePost(
            @PathVariable Long postId,
            @RequestParam String status) {
        return ResponseEntity.ok(AdminPostResponseDTO.from(adminService.moderatePost(postId, status)));
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponseDTO>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<UserResponseDTO> getUser(@PathVariable Long userId) {
        return ResponseEntity.ok(adminService.getUser(userId));
    }

    @PutMapping("/users/{userId}/toggle-status")
    public ResponseEntity<Map<String, Object>> toggleUserStatus(@PathVariable Long userId) {
        return ResponseEntity.ok(adminService.toggleUserStatus(userId));
    }
}
