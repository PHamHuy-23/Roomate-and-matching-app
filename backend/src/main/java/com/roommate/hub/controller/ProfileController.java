package com.roommate.hub.controller;

import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;
    private final UserRepository userRepository;

    @GetMapping("/preferences/{userId}")
    public ResponseEntity<UserPreferenceDTO> getPreferences(@PathVariable Long userId) {
        UserPreferenceDTO pref = profileService.getPreferences(userId);
        return ResponseEntity.ok(pref);
    }

    @PutMapping("/preferences/{userId}")
    public ResponseEntity<UserPreferenceDTO> savePreferences(
            @PathVariable Long userId,
            @Valid @RequestBody UserPreferenceDTO dto) {
        return ResponseEntity.ok(profileService.saveOrUpdatePreferences(userId, dto));
    }

    @PutMapping("/user/{userId}")
    public ResponseEntity<User> updateUserInfo(
            @PathVariable Long userId,
            @RequestParam String fullName,
            @RequestParam String phone,
            @RequestParam String gender,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate birthDate,
            @RequestParam(required = false) String university) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));
        user.setFullName(fullName);
        user.setPhone(phone);
        user.setGender(gender.toUpperCase());
        if (birthDate != null) {
            user.setBirthDate(birthDate);
        }
        if (university != null) {
            user.setUniversity(university.trim());
        }
        return ResponseEntity.ok(userRepository.save(user));
    }
}
