package com.roommate.hub.controller;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.roommate.hub.dto.ConfirmAvatarRequest;
import com.roommate.hub.dto.CreateUploadRequest;
import com.roommate.hub.dto.UploadUrlResponse;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.R2StorageService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/uploads")
@RequiredArgsConstructor
@ConditionalOnProperty(name = "storage.r2.enabled", havingValue = "true")
public class UploadController {

    private final R2StorageService storageService;
    private final UserRepository userRepository;

    @PostMapping("/presign")
    public ResponseEntity<UploadUrlResponse> createUpload(
            @Valid @RequestBody CreateUploadRequest request) {
        User currentUser = currentUser();
        return ResponseEntity.ok(storageService.createUpload(currentUser.getId(), request));
    }

    @PutMapping("/avatar")
    public ResponseEntity<UserResponseDTO> confirmAvatar(
            @Valid @RequestBody ConfirmAvatarRequest request) {
        User currentUser = currentUser();
        currentUser.setAvatarUrl(storageService.requireOwnedObject(
                currentUser.getId(), "avatar", request.objectKey()));
        return ResponseEntity.ok(UserResponseDTO.from(userRepository.save(currentUser)));
    }

    private User currentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.UNAUTHORIZED));
    }
}
