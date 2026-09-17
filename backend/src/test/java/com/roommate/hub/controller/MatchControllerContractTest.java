package com.roommate.hub.controller;

import com.roommate.hub.dto.MatchCriteriaDetailDTO;
import com.roommate.hub.dto.MatchRecommendationDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.MatchRequestService;
import com.roommate.hub.service.MatchingService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.Optional;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MatchControllerContractTest {

    @Test
    void recommendationsResponseContainsAgeAndUniversity() throws Exception {
        MatchingService matchingService = mock(MatchingService.class);
        MatchRequestService matchRequestService = mock(MatchRequestService.class);
        UserRepository userRepository = mock(UserRepository.class);
        MatchController controller = new MatchController(
                matchingService,
                matchRequestService,
                userRepository
        );
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

        User currentUser = User.builder().id(1L).gender("MALE").build();
        MatchRecommendationDTO recommendation = MatchRecommendationDTO.builder()
                .userId(2L)
                .fullName("Văn Nam")
                .age(22)
                .university("Đại học Sư phạm Kỹ thuật TP.HCM")
                .targetDistrict("Thu Duc")
                .budgetAmount(2_100_000.0)
                .totalScore(94.0)
                .criteriaDetail(MatchCriteriaDetailDTO.builder()
                        .budgetMatch(95.0)
                        .sleepMatch(100.0)
                        .cleanlinessMatch(100.0)
                        .smokingMatch(100.0)
                        .petMatch(100.0)
                        .build())
                .build();

        when(userRepository.findById(1L)).thenReturn(Optional.of(currentUser));
        when(matchingService.getRecommendations(currentUser)).thenReturn(List.of(recommendation));

        mockMvc.perform(get("/api/v1/matches/recommendations/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].age").value(22))
                .andExpect(jsonPath("$[0].university")
                        .value("Đại học Sư phạm Kỹ thuật TP.HCM"));
    }
}
