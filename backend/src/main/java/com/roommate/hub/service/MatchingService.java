package com.roommate.hub.service;

import com.roommate.hub.dto.MatchCriteriaDetailDTO;
import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.util.DistrictNames;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.Period;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchingService {

    private final UserPreferenceRepository preferenceRepository;
    private final com.roommate.hub.repository.BlockedUserRepository blockedUserRepository;

    public List<MatchRecommendationDTO> getRecommendations(User currentUser) {
        if (!"ACTIVE".equalsIgnoreCase(currentUser.getStatus()) || !currentUser.isSearchActive()) return List.of();
        java.util.Optional<UserPreference> myPrefOpt = preferenceRepository.findByUserId(currentUser.getId());
        if (myPrefOpt.isEmpty()) {
            return java.util.Collections.emptyList();
        }
        UserPreference myPref = myPrefOpt.get();

        // Filter district aliases after loading so legacy rows need no destructive migration.
        List<UserPreference> candidates = preferenceRepository.findCandidatesByGender(
                currentUser.getId(),
                myPref.getTargetGender() == null ? currentUser.getGender() : myPref.getTargetGender()
        );

        // Lọc bỏ những người dùng bị chặn hoặc đã chặn người dùng hiện tại
        java.util.Set<Long> blockedUserIds = new java.util.HashSet<>();
        if (blockedUserRepository != null) {
            blockedUserRepository.findByUserId(currentUser.getId())
                    .forEach(b -> blockedUserIds.add(b.getBlockedUser().getId()));
            blockedUserRepository.findByBlockedUserId(currentUser.getId())
                    .forEach(b -> blockedUserIds.add(b.getUser().getId()));
        }

        // 2. TÍNH TOÁN % TỔNG THỂ & CHI TIẾT TỪNG TIÊU CHÍ (QĐ 1)
        return candidates.stream()
                .filter(candidate -> DistrictNames.same(myPref.getTargetDistrict(), candidate.getTargetDistrict()))
                .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getUser().getStatus()) && candidate.getUser().isSearchActive())
                .filter(candidate -> candidate.getTargetGender() == null || "ANY".equals(candidate.getTargetGender()) || currentUser.getGender().equals(candidate.getTargetGender()))
                .filter(candidate -> !"SMOKING".equals(myPref.getTopPriority()) || !Boolean.TRUE.equals(candidate.getIsSmoking()))
                .filter(candidate -> !blockedUserIds.contains(candidate.getUser().getId()))
                .map(candidate -> {
                    MatchCriteriaDetailDTO details = calculateCriteriaDetail(myPref, candidate);
                    double budgetWeight = "BUDGET".equals(myPref.getTopPriority()) ? 0.60 : 0.30;
                    double sleepWeight = "SLEEP".equals(myPref.getTopPriority()) ? 0.50 : 0.25;
                    double cleanWeight = "CLEAN".equals(myPref.getTopPriority()) ? 0.40 : 0.20;
                    double total = (budgetWeight * details.getBudgetMatch()
                            + sleepWeight * details.getSleepMatch()
                            + cleanWeight * details.getCleanlinessMatch()
                            + 0.15 * details.getSmokingMatch()
                            + 0.10 * details.getPetMatch()) / (budgetWeight + sleepWeight + cleanWeight + 0.25);

                    double roundedTotal = Math.round(total * 10.0) / 10.0;

                    return MatchRecommendationDTO.builder()
                            .userId(candidate.getUser().getId())
                            .fullName(candidate.getUser().getFullName())
                            .avatarUrl(candidate.getUser().getAvatarUrl())
                            .age(calculateAge(candidate.getUser().getBirthDate()))
                            .university(candidate.getUser().getUniversity())
                            .targetDistrict(DistrictNames.canonical(candidate.getTargetDistrict()))
                            .budgetAmount(candidate.getBudgetAmount())
                            .bioDescription(candidate.getBioDescription())
                            .totalScore(roundedTotal)
                            .criteriaDetail(details)
                            .build();
                })
                .sorted(Comparator.comparingDouble(MatchRecommendationDTO::getTotalScore).reversed())
                .collect(Collectors.toList());
    }

    private Integer calculateAge(LocalDate birthDate) {
        if (birthDate == null) {
            return null;
        }
        return Period.between(birthDate, LocalDate.now()).getYears();
    }

    public MatchCriteriaDetailDTO calculateCriteriaDetail(UserPreference a, UserPreference b) {
        // Ngân sách: độ lệch tương đối
        double maxBudget = Math.max(a.getBudgetAmount(), b.getBudgetAmount());
        double simBudget = (maxBudget == 0) ? 1.0 : 1.0 - (Math.abs(a.getBudgetAmount() - b.getBudgetAmount()) / maxBudget);
        if (a.getBudgetMin() != null && a.getBudgetMax() != null && b.getBudgetMin() != null && b.getBudgetMax() != null) {
            double gap = Math.max(a.getBudgetMin(), b.getBudgetMin()) - Math.min(a.getBudgetMax(), b.getBudgetMax());
            simBudget = gap <= 0 ? 1.0 : Math.max(0.0, 1.0 - gap / 5_000_000.0);
        }

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
