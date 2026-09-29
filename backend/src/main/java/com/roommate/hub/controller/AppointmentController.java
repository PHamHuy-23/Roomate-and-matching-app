package com.roommate.hub.controller;

import com.roommate.hub.dto.AppointmentResponseDTO;
import com.roommate.hub.dto.CreateAppointmentDTO;
import com.roommate.hub.service.AppointmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/appointments")
@RequiredArgsConstructor
public class AppointmentController {

    private final AppointmentService appointmentService;

    @PostMapping
    public ResponseEntity<AppointmentResponseDTO> createAppointment(
            @Valid @RequestBody CreateAppointmentDTO dto) {
        return ResponseEntity.ok(appointmentService.createAppointment(dto));
    }

    @GetMapping("/my")
    public ResponseEntity<List<AppointmentResponseDTO>> getMyAppointments() {
        return ResponseEntity.ok(appointmentService.getMyAppointments());
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<AppointmentResponseDTO> updateStatus(
            @PathVariable Long id,
            @RequestParam String status) {
        return ResponseEntity.ok(appointmentService.updateStatus(id, status));
    }
}
