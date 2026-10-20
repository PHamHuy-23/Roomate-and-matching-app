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
import com.roommate.hub.service.ReportExportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final DatabaseBackupService databaseBackupService;
    private final ReportExportService reportExportService;

    private static final DateTimeFormatter FILE_DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");

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

    // --- CÁC API XUẤT BÁO CÁO DỮ LIỆU (CSV / EXCEL COMPATIBLE) ---

    @GetMapping("/export/audit-logs")
    public ResponseEntity<byte[]> exportAuditLogs() {
        String filename = "audit_logs_" + LocalDate.now().format(FILE_DATE_FORMATTER) + ".csv";
        byte[] csvData = reportExportService.exportAuditLogsCsv();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csvData);
    }

    @GetMapping("/export/users")
    public ResponseEntity<byte[]> exportUsers() {
        String filename = "users_" + LocalDate.now().format(FILE_DATE_FORMATTER) + ".csv";
        byte[] csvData = reportExportService.exportUsersCsv();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csvData);
    }

    @GetMapping("/export/posts")
    public ResponseEntity<byte[]> exportPosts() {
        String filename = "posts_" + LocalDate.now().format(FILE_DATE_FORMATTER) + ".csv";
        byte[] csvData = reportExportService.exportPostsCsv();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csvData);
    }

    @GetMapping("/export/overview")
    public ResponseEntity<byte[]> exportSystemOverview() {
        String filename = "system_overview_" + LocalDate.now().format(FILE_DATE_FORMATTER) + ".csv";
        byte[] csvData = reportExportService.exportSystemOverviewCsv();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csvData);
    }
}
