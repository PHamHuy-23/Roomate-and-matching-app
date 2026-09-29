package com.roommate.hub.controller;

import com.roommate.hub.dto.BlockedUserDTO;
import com.roommate.hub.service.BlockService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/blocks")
@RequiredArgsConstructor
public class BlockController {

    private final BlockService blockService;

    @GetMapping
    public ResponseEntity<List<BlockedUserDTO>> getMyBlockedUsers() {
        return ResponseEntity.ok(blockService.getMyBlockedUsers());
    }

    @PostMapping
    public ResponseEntity<BlockedUserDTO> blockUser(@RequestParam Long targetUserId) {
        return ResponseEntity.ok(blockService.blockUser(targetUserId));
    }

    @DeleteMapping("/{targetUserId}")
    public ResponseEntity<Map<String, String>> unblockUser(@PathVariable Long targetUserId) {
        blockService.unblockUser(targetUserId);
        return ResponseEntity.ok(Map.of("message", "Đã bỏ chặn người dùng thành công"));
    }
}
