package com.roommate.hub.service;

import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.UserPreferenceRepository;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MatchingServiceTest {

    private final UserPreferenceRepository preferenceRepository = mock(UserPreferenceRepository.class);
    private final com.roommate.hub.repository.BlockedUserRepository blockedUserRepository = mock(com.roommate.hub.repository.BlockedUserRepository.class);
    private final MatchingService matchingService = new MatchingService(preferenceRepository, blockedUserRepository);

    @Test
    void returnsEmptyListWhenUserHasNoPreference() {
        User currentUser = User.builder().id(99L).gender("MALE").build();
        when(preferenceRepository.findByUserId(99L)).thenReturn(Optional.empty());

        List<MatchRecommendationDTO> recommendations = matchingService.getRecommendations(currentUser);
        assertThat(recommendations).isEmpty();
    }

    @Test
    void mapsPersistedAcademicProfileIntoRecommendations() {
        User currentUser = User.builder()
                .id(1L)
                .gender("MALE")
                .build();
        UserPreference currentPreference = preference(currentUser, 2_000_000.0);

        LocalDate birthDate = LocalDate.of(2003, 9, 18);
        User candidate = User.builder()
                .id(2L)
                .fullName("Văn Nam")
                .gender("MALE")
                .birthDate(birthDate)
                .university("Đại học Sư phạm Kỹ thuật TP.HCM")
                .build();
        UserPreference candidatePreference = preference(candidate, 2_100_000.0);

        when(preferenceRepository.findByUserId(1L)).thenReturn(Optional.of(currentPreference));
        when(preferenceRepository.findCandidatesByGender(1L, "MALE"))
                .thenReturn(List.of(candidatePreference));
        when(blockedUserRepository.findByUserId(1L)).thenReturn(List.of());
        when(blockedUserRepository.findByBlockedUserId(1L)).thenReturn(List.of());

        List<MatchRecommendationDTO> recommendations = matchingService.getRecommendations(currentUser);

        assertThat(recommendations).hasSize(1);
        MatchRecommendationDTO recommendation = recommendations.getFirst();
        assertThat(recommendation.getAge())
                .isEqualTo(Period.between(birthDate, LocalDate.now()).getYears());
        assertThat(recommendation.getUniversity())
                .isEqualTo("Đại học Sư phạm Kỹ thuật TP.HCM");
    }

    private UserPreference preference(User user, double budget) {
        return UserPreference.builder()
                .user(user)
                .targetDistrict("Thu Duc")
                .budgetAmount(budget)
                .sleepHabit(1)
                .cleanlinessLevel(4)
                .isSmoking(false)
                .allowPets(false)
                .bioDescription("Hòa đồng")
                .build();
    }
}
