package com.roommate.hub.controller;

import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;
    private final UserRepository userRepository;
    private final com.roommate.hub.repository.RoomPostRepository roomPostRepository;

    @GetMapping("/public/{userId}")
    public com.roommate.hub.dto.PublicProfileResponseDTO getPublicProfile(@PathVariable Long userId) {
        return profileService.getPublicProfile(userId);
    }

    @GetMapping("/saved-posts")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public java.util.Set<Long> getSavedPosts() {
        return java.util.Set.copyOf(currentUser().getSavedPostIds());
    }

    @PutMapping("/saved-posts/{postId}")
    @org.springframework.transaction.annotation.Transactional
    public java.util.Map<String, Boolean> setSavedPost(@PathVariable Long postId, @RequestBody java.util.Map<String, Boolean> body) {
        Boolean saved = body.get("saved");
        if (saved == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu trạng thái lưu phòng");
        User user = currentUser();
        user = userRepository.findByIdForUpdate(user.getId()).orElseThrow();
        if (saved) {
            roomPostRepository.findByIdAndStatusIn(postId, java.util.List.of(com.roommate.hub.entity.RoomPost.PostStatus.APPROVED, com.roommate.hub.entity.RoomPost.PostStatus.AVAILABLE))
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin không còn hiển thị"));
            user.getSavedPostIds().add(postId);
        } else user.getSavedPostIds().remove(postId);
        userRepository.save(user);
        return java.util.Map.of("saved", saved);
    }

    @GetMapping("/search-status")
    public java.util.Map<String, Boolean> getSearchStatus() {
        return java.util.Map.of("searchActive", currentUser().isSearchActive());
    }

    @PutMapping("/search-status")
    public java.util.Map<String, Boolean> updateSearchStatus(@RequestBody java.util.Map<String, Boolean> body) {
        Boolean value = body.get("searchActive");
        if (value == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu trạng thái tìm bạn");
        User user = currentUser();
        user.setSearchActive(value);
        userRepository.save(user);
        return java.util.Map.of("searchActive", value);
    }

    private User currentUser() {
        return userRepository.findByEmail(SecurityContextHolder.getContext().getAuthentication().getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    }

    @GetMapping("/preferences/{userId}")
    public ResponseEntity<UserPreferenceDTO> getPreferences(@PathVariable Long userId) {
        assertCurrentUser(userId);
        UserPreferenceDTO pref = profileService.getPreferences(userId);
        if (pref == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(pref);
    }

    @PutMapping("/preferences/{userId}")
    public ResponseEntity<UserPreferenceDTO> savePreferences(
            @PathVariable Long userId,
            @Valid @RequestBody UserPreferenceDTO dto) {
        assertCurrentUser(userId);
        return ResponseEntity.ok(profileService.saveOrUpdatePreferences(userId, dto));
    }

    @PutMapping("/user/{userId}")
    public ResponseEntity<UserResponseDTO> updateUserInfo(
            @PathVariable Long userId,
            @RequestParam String fullName,
            @RequestParam String phone,
            @RequestParam String gender,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate birthDate,
            @RequestParam(required = false) String university) {
        assertCurrentUser(userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));
        user.setFullName(fullName);
        user.setPhone(phone);
        user.setGender(gender.toUpperCase());
        if (birthDate != null) {
            if (birthDate.isAfter(LocalDate.now().minusYears(18))) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Người dùng phải đủ 18 tuổi"
                );
            }
            user.setBirthDate(birthDate);
        }
        if (university != null) {
            String normalizedUniversity = university.trim();
            if (normalizedUniversity.isEmpty() || normalizedUniversity.length() > 150) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Trường đại học không hợp lệ"
                );
            }
            user.setUniversity(normalizedUniversity);
        }
        return ResponseEntity.ok(UserResponseDTO.from(userRepository.save(user)));
    }

    private void assertCurrentUser(Long userId) {
        User current = userRepository.findByEmail(SecurityContextHolder.getContext().getAuthentication().getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!current.getId().equals(userId) && current.getRole() != User.Role.ROLE_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Không có quyền truy cập tài khoản này");
        }
    }
}
