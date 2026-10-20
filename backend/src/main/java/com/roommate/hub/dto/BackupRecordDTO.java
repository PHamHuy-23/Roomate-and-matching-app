package com.roommate.hub.dto;

import java.time.LocalDateTime;

public record BackupRecordDTO(
        String id,
        String fileName,
        String backupType, // "DAILY_AUTO" hoặc "MANUAL"
        String sizeFormatted,
        LocalDateTime createdAt,
        String downloadUrl,
        String status
) {}
