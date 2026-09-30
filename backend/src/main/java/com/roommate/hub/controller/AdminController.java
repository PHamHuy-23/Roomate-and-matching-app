package com.roommate.hub.controller;

import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.dto.AdminReportResponseDTO;
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
            @RequestParam String status,
            @RequestParam(required = false) String reason) {
        return ResponseEntity.ok(AdminPostResponseDTO.from(adminService.moderatePost(postId, status, reason)));
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponseDTO>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<UserResponseDTO> getUser(@PathVariable Long userId) {
        return ResponseEntity.ok(adminService.getUser(userId));
    }

    @RequestMapping(value = {"/users/{userId}/toggle-status", "/users/{userId}/status"}, method = {RequestMethod.PUT, RequestMethod.PATCH})
    public ResponseEntity<Map<String, Object>> toggleUserStatus(@PathVariable Long userId) {
        return ResponseEntity.ok(adminService.toggleUserStatus(userId));
    }

    @GetMapping("/reports")
    public ResponseEntity<List<AdminReportResponseDTO>> getAllReports() {
        return ResponseEntity.ok(adminService.getAllReports());
    }

    @RequestMapping(value = {"/reports/{reportId}/moderate", "/reports/{reportId}/resolve"}, method = {RequestMethod.PUT, RequestMethod.PATCH})
    public ResponseEntity<AdminReportResponseDTO> moderateReport(
            @PathVariable Long reportId,
            @RequestParam(defaultValue = "RESOLVED") String status,
            @RequestParam(required = false) String note) {
        return ResponseEntity.ok(adminService.moderateReport(reportId, status, note));
    }
}
