package com.roommate.hub.controller;

import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.dto.AdminReportResponseDTO;
import com.roommate.hub.dto.AuditLogResponseDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.dto.AdminDashboardStatsDTO;
import com.roommate.hub.dto.AdminPostResponseDTO;
import com.roommate.hub.dto.UpdateUserStatusDTO;
import com.roommate.hub.dto.BackupRecordDTO;
import com.roommate.hub.service.AdminService;
import com.roommate.hub.service.DatabaseBackupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final DatabaseBackupService databaseBackupService;

    @GetMapping("/stats")
    public ResponseEntity<AdminDashboardStatsDTO> getDashboardStats() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(adminService.getDashboardStats());
    }

    @GetMapping("/posts")
    public ResponseEntity<List<AdminPostResponseDTO>> getAllPosts() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(adminService.getAllPostsForModeration());
    }

    @PutMapping("/posts/{postId}/moderate")
    public ResponseEntity<AdminPostResponseDTO> moderatePost(
            @PathVariable Long postId,
            @RequestParam String status,
            @RequestParam(required = false) String reason,
            @RequestParam Long expectedVersion) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(AdminPostResponseDTO.from(adminService.moderatePost(postId, status, reason, expectedVersion)));
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
    public ResponseEntity<Map<String, Object>> setUserStatus(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateUserStatusDTO body) {
        return ResponseEntity.ok(adminService.setUserStatus(userId, body.getStatus()));
    }

    @GetMapping("/reports")
    public ResponseEntity<List<AdminReportResponseDTO>> getAllReports() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(adminService.getAllReports());
    }

    @RequestMapping(value = {"/reports/{reportId}/moderate", "/reports/{reportId}/resolve"}, method = {RequestMethod.PUT, RequestMethod.PATCH})
    public ResponseEntity<AdminReportResponseDTO> moderateReport(
            @PathVariable Long reportId,
            @RequestParam(defaultValue = "RESOLVED") String status,
            @RequestParam(required = false) String note) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(adminService.moderateReport(reportId, status, note));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLogResponseDTO>> getAuditLogs() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(adminService.getAuditLogs());
    }

    // --- CÁC API QUẢN LÝ SAO LƯU & KHÔI PHỤC (BACKUP & RESTORE) ---

    @GetMapping("/backups")
    public ResponseEntity<List<BackupRecordDTO>> getAllBackups() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(databaseBackupService.getAllBackups());
    }

    @PostMapping("/backups/create")
    public ResponseEntity<BackupRecordDTO> triggerBackup(@RequestParam(defaultValue = "MANUAL") String type) {
        return ResponseEntity.ok(databaseBackupService.triggerBackup(type));
    }

    @PostMapping("/backups/reset-demo")
    public ResponseEntity<Map<String, Object>> resetDemoState() {
        return ResponseEntity.ok(databaseBackupService.rollbackDemoState());
    }

    @PostMapping("/backups/{backupId}/restore")
    public ResponseEntity<Map<String, Object>> restoreFromBackup(@PathVariable String backupId) {
        return ResponseEntity.ok(databaseBackupService.restoreFromBackup(backupId));
    }
}
