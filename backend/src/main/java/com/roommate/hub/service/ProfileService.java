package com.roommate.hub.service;

import com.roommate.hub.dto.UserPreferenceDTO;
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

    public UserPreferenceDTO getPreferences(Long userId) {
        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(null);

        if (pref == null) {
            return null;
        }

        return UserPreferenceDTO.builder()
                .targetDistrict(pref.getTargetDistrict())
                .budgetAmount(pref.getBudgetAmount())
                .sleepHabit(pref.getSleepHabit())
                .cleanlinessLevel(pref.getCleanlinessLevel())
                .isSmoking(pref.getIsSmoking())
                .allowPets(pref.getAllowPets())
                .bioDescription(pref.getBioDescription())
                .build();
    }

    @Transactional
    public UserPreferenceDTO saveOrUpdatePreferences(Long userId, UserPreferenceDTO dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));

        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(UserPreference.builder().user(user).build());

        pref.setTargetDistrict(dto.getTargetDistrict());
        pref.setBudgetAmount(dto.getBudgetAmount());
        pref.setSleepHabit(dto.getSleepHabit());
        pref.setCleanlinessLevel(dto.getCleanlinessLevel());
        pref.setIsSmoking(dto.getIsSmoking());
        pref.setAllowPets(dto.getAllowPets());
        pref.setBioDescription(dto.getBioDescription());

        preferenceRepository.save(pref);
        return dto;
    }
}