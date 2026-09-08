package com.roommate.hub.controller;

import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.dto.RoomPostResponseDTO;
import com.roommate.hub.service.RoomPostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class RoomPostController {

    private final RoomPostService roomPostService;

    @GetMapping
    public ResponseEntity<List<RoomPostResponseDTO>> getAllPosts() {
        return ResponseEntity.ok(roomPostService.getAllAvailablePosts());
    }

    @PostMapping
    public ResponseEntity<RoomPostResponseDTO> createPost(@Valid @RequestBody CreateRoomPostDTO dto) {
        return ResponseEntity.ok(roomPostService.createPost(dto));
    }
}