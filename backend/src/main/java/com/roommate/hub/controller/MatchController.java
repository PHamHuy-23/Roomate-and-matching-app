package com.roommate.hub.controller;

import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.dto.MatchRequestResponseDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.MatchRequestService;
import com.roommate.hub.service.MatchingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchingService matchingService;
    private final MatchRequestService matchRequestService;
    private final UserRepository userRepository;

    // Gợi ý bạn trọ cho User ID cụ thể[cite: 1]
    @GetMapping("/recommendations/{userId}")
    public ResponseEntity<List<MatchRecommendationDTO>> getRecommendations(@PathVariable Long userId) {
        assertCurrentUser(userId);
        User currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User không tồn tại!"));
        return ResponseEntity.ok(matchingService.getRecommendations(currentUser));
    }

    @GetMapping("/requests/received/{userId}")
    public ResponseEntity<List<MatchRequestResponseDTO>> getReceivedRequests(@PathVariable Long userId) {
        assertCurrentUser(userId);
        return ResponseEntity.ok(matchRequestService.getReceivedRequests(userId));
    }

    @GetMapping("/requests/sent/{userId}")
    public ResponseEntity<List<MatchRequestResponseDTO>> getSentRequests(@PathVariable Long userId) {
        assertCurrentUser(userId);
        return ResponseEntity.ok(matchRequestService.getSentRequests(userId));
    }

    // Gửi yêu cầu kết nối[cite: 1]
    @PostMapping("/requests")
    public ResponseEntity<MatchRequestResponseDTO> sendRequest(
            @RequestParam Long receiverId) {
        return ResponseEntity.ok(matchRequestService.sendRequest(currentUserId(), receiverId));
    }

    // Phản hồi yêu cầu (Chấp nhận / Từ chối)[cite: 1]
    @PutMapping("/requests/{requestId}/respond")
    public ResponseEntity<Map<String, Object>> respondRequest(
            @PathVariable Long requestId,
            @RequestParam boolean accept) {
        return ResponseEntity.ok(matchRequestService.respondRequest(requestId, accept, currentUserId()));
    }

    private Long currentUserId() { return userRepository.findByEmail(SecurityContextHolder.getContext().getAuthentication().getName()).orElseThrow().getId(); }
    private void assertCurrentUser(Long userId) { if (!currentUserId().equals(userId)) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN); }
}
