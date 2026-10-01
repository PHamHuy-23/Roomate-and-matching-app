package com.roommate.hub.service;

import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.dto.PublicProfileResponseDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserPreferenceRepository preferenceRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public PublicProfileResponseDTO getPublicProfile(Long userId) {
        User user = userRepository.findById(userId)
                .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getStatus()) && candidate.isSearchActive())
                .orElseThrow(() -> new com.roommate.hub.exception.ResourceNotFoundException("Hồ sơ không còn công khai"));
        UserPreference pref = preferenceRepository.findByUserId(userId).orElse(null);
        return PublicProfileResponseDTO.builder()
                .userId(user.getId()).fullName(user.getFullName()).avatarUrl(user.getAvatarUrl()).university(user.getUniversity())
                .targetDistrict(pref == null ? null : pref.getTargetDistrict())
                .budgetMin(pref == null ? null : pref.getBudgetMin()).budgetMax(pref == null ? null : pref.getBudgetMax())
                .sleepHabit(pref == null ? null : pref.getSleepHabit()).cleanlinessLevel(pref == null ? null : pref.getCleanlinessLevel())
                .isSmoking(pref == null ? null : pref.getIsSmoking()).allowPets(pref == null ? null : pref.getAllowPets())
                .bioDescription(pref == null ? null : pref.getBioDescription()).build();
    }

    public UserPreferenceDTO getPreferences(Long userId) {
        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(null);

        if (pref == null) {
            return null;
        }

        return UserPreferenceDTO.builder()
                .targetDistrict(pref.getTargetDistrict())
                .budgetAmount(pref.getBudgetAmount())
                .budgetMin(pref.getBudgetMin()).budgetMax(pref.getBudgetMax())
                .targetGender(pref.getTargetGender()).topPriority(pref.getTopPriority())
                .sleepHabit(pref.getSleepHabit())
                .cleanlinessLevel(pref.getCleanlinessLevel())
                .isSmoking(pref.getIsSmoking())
                .allowPets(pref.getAllowPets())
                .bioDescription(pref.getBioDescription())
                .build();
    }

    @Transactional
    public UserPreferenceDTO saveOrUpdatePreferences(Long userId, UserPreferenceDTO dto) {
        if ((dto.getBudgetAmount() != null && !Double.isFinite(dto.getBudgetAmount()))
                || (dto.getBudgetMin() != null && !Double.isFinite(dto.getBudgetMin()))
                || (dto.getBudgetMax() != null && !Double.isFinite(dto.getBudgetMax()))) {
            throw new IllegalArgumentException("Ngân sách phải là số hữu hạn");
        }
        if ((dto.getBudgetMin() == null) != (dto.getBudgetMax() == null)
                || (dto.getBudgetMin() != null && dto.getBudgetMin() > dto.getBudgetMax())) {
            throw new IllegalArgumentException("Khoảng ngân sách không hợp lệ");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));

        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(UserPreference.builder().user(user).build());

        pref.setTargetDistrict(dto.getTargetDistrict());
        pref.setBudgetAmount(dto.getBudgetAmount());
        pref.setBudgetMin(dto.getBudgetMin()); pref.setBudgetMax(dto.getBudgetMax());
        pref.setTargetGender(dto.getTargetGender()); pref.setTopPriority(dto.getTopPriority());
        pref.setSleepHabit(dto.getSleepHabit());
        pref.setCleanlinessLevel(dto.getCleanlinessLevel());
        pref.setIsSmoking(dto.getIsSmoking());
        pref.setAllowPets(dto.getAllowPets());
        pref.setBioDescription(dto.getBioDescription());

        preferenceRepository.save(pref);
        return dto;
    }
}
