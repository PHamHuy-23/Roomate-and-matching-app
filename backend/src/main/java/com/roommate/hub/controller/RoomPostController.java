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

    @GetMapping("/my")
    public ResponseEntity<List<RoomPostResponseDTO>> getMyPosts() {
        return ResponseEntity.ok(roomPostService.getMyPosts());
    }

    @PostMapping
    public ResponseEntity<RoomPostResponseDTO> createPost(@Valid @RequestBody CreateRoomPostDTO dto) {
        return ResponseEntity.ok(roomPostService.createPost(dto));
    }

    @PutMapping("/{postId}")
    public ResponseEntity<RoomPostResponseDTO> updatePost(@PathVariable Long postId, @RequestBody CreateRoomPostDTO dto) {
        return ResponseEntity.ok(roomPostService.updatePost(postId, dto));
    }

    @GetMapping("/{postId}")
    public ResponseEntity<RoomPostResponseDTO> getPost(@PathVariable Long postId) {
        return ResponseEntity.ok(roomPostService.getPost(postId));
    }

    @DeleteMapping("/{postId}")
    public ResponseEntity<Void> deletePost(@PathVariable Long postId) {
        roomPostService.deletePost(postId);
        return ResponseEntity.noContent().build();
    }
}
