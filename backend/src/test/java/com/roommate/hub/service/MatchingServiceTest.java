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
    private final MatchingService matchingService = new MatchingService(preferenceRepository);

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
        when(preferenceRepository.findCandidates(1L, "MALE", "Thu Duc"))
                .thenReturn(List.of(candidatePreference));

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
