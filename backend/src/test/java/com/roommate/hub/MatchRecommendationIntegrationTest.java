package com.roommate.hub;

import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.MatchingService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class MatchRecommendationIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserPreferenceRepository preferenceRepository;

    @Autowired
    private MatchingService matchingService;

    @Test
    void persistedAcademicProfileIsReturnedByRecommendationService() {
        String suffix = UUID.randomUUID().toString();
        User currentUser = userRepository.save(User.builder()
                .email("current-" + suffix + "@integration.test")
                .passwordHash("test-password-hash")
                .fullName("Current User")
                .gender("MALE")
                .role(User.Role.ROLE_USER)
                .build());
        preferenceRepository.save(preference(currentUser, 2_000_000.0));

        LocalDate birthDate = LocalDate.of(2003, 9, 18);
        User candidate = userRepository.save(User.builder()
                .email("candidate-" + suffix + "@integration.test")
                .passwordHash("test-password-hash")
                .fullName("Văn Nam")
                .gender("MALE")
                .birthDate(birthDate)
                .university("Đại học Sư phạm Kỹ thuật TP.HCM")
                .role(User.Role.ROLE_USER)
                .build());
        preferenceRepository.save(preference(candidate, 2_100_000.0));

        MatchRecommendationDTO result = matchingService.getRecommendations(currentUser).stream()
                .filter(item -> item.getUserId().equals(candidate.getId()))
                .findFirst()
                .orElseThrow();

        assertThat(result.getAge())
                .isEqualTo(Period.between(birthDate, LocalDate.now()).getYears());
        assertThat(result.getUniversity())
                .isEqualTo("Đại học Sư phạm Kỹ thuật TP.HCM");
    }

    private UserPreference preference(User user, double budget) {
        return UserPreference.builder()
                .user(user)
                .targetDistrict("Integration Test District")
                .budgetAmount(budget)
                .sleepHabit(1)
                .cleanlinessLevel(4)
                .isSmoking(false)
                .allowPets(false)
                .bioDescription("Integration test data")
                .build();
    }
}
