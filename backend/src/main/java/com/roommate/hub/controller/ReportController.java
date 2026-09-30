package com.roommate.hub.controller;

import com.roommate.hub.dto.CreateReportDTO;
import com.roommate.hub.service.ReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> submitReport(@Valid @RequestBody CreateReportDTO dto) {
        return ResponseEntity.ok(reportService.createReport(dto));
    }
}
