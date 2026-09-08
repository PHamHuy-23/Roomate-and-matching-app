package com.roommate.hub.service;

import com.roommate.hub.dto.MatchCriteriaDetailDTO;
import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.UserPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchingService {

    private final UserPreferenceRepository preferenceRepository;

    public List<MatchRecommendationDTO> getRecommendations(User currentUser) {
        UserPreference myPref = preferenceRepository.findByUserId(currentUser.getId())
                .orElseThrow(() -> new RuntimeException("Vui lòng hoàn thành khảo sát thói quen trước!"));

        // 1. LỌC CỨNG (SQL): Cùng giới tính & cùng quận
        List<UserPreference> candidates = preferenceRepository.findCandidates(
                currentUser.getId(),
                currentUser.getGender(),
                myPref.getTargetDistrict()
        );

        // 2. TÍNH TOÁN % TỔNG THỂ & CHI TIẾT TỪNG TIÊU CHÍ (QĐ 1)
        return candidates.stream()
                .map(candidate -> {
                    MatchCriteriaDetailDTO details = calculateCriteriaDetail(myPref, candidate);
                    double total = (0.30 * details.getBudgetMatch())
                            + (0.25 * details.getSleepMatch())
                            + (0.20 * details.getCleanlinessMatch())
                            + (0.15 * details.getSmokingMatch())
                            + (0.10 * details.getPetMatch());

                    double roundedTotal = Math.round(total * 10.0) / 10.0;

                    return MatchRecommendationDTO.builder()
                            .userId(candidate.getUser().getId())
                            .fullName(candidate.getUser().getFullName())
                            .avatarUrl(candidate.getUser().getAvatarUrl())
                            .targetDistrict(candidate.getTargetDistrict())
                            .budgetAmount(candidate.getBudgetAmount())
                            .bioDescription(candidate.getBioDescription())
                            .totalScore(roundedTotal)
                            .criteriaDetail(details)
                            .build();
                })
                .sorted(Comparator.comparingDouble(MatchRecommendationDTO::getTotalScore).reversed())
                .collect(Collectors.toList());
    }

    public MatchCriteriaDetailDTO calculateCriteriaDetail(UserPreference a, UserPreference b) {
        // Ngân sách: độ lệch tương đối
        double maxBudget = Math.max(a.getBudgetAmount(), b.getBudgetAmount());
        double simBudget = (maxBudget == 0) ? 1.0 : 1.0 - (Math.abs(a.getBudgetAmount() - b.getBudgetAmount()) / maxBudget);

        // Giờ giấc ngủ (thang đo 1-3)[cite: 1]
        double simSleep = 1.0 - (Math.abs(a.getSleepHabit() - b.getSleepHabit()) / 2.0);

        // Mức độ sạch sẽ (thang đo 1-5)[cite: 1]
        double simClean = 1.0 - (Math.abs(a.getCleanlinessLevel() - b.getCleanlinessLevel()) / 4.0);

        // Thói quen hút thuốc[cite: 1]
        double simSmoke = a.getIsSmoking().equals(b.getIsSmoking()) ? 1.0 : 0.0;

        // Thói quen nuôi thú cưng[cite: 1]
        double simPet = a.getAllowPets().equals(b.getAllowPets()) ? 1.0 : 0.0;

        return MatchCriteriaDetailDTO.builder()
                .budgetMatch(Math.round(simBudget * 100.0 * 10.0) / 10.0)
                .sleepMatch(Math.round(simSleep * 100.0 * 10.0) / 10.0)
                .cleanlinessMatch(Math.round(simClean * 100.0 * 10.0) / 10.0)
                .smokingMatch(Math.round(simSmoke * 100.0 * 10.0) / 10.0)
                .petMatch(Math.round(simPet * 100.0 * 10.0) / 10.0)
                .build();
    }
}