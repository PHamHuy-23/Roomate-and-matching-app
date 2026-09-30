package com.roommate.hub;

import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import com.roommate.hub.service.*;
import com.roommate.hub.controller.ProfileController;
import com.roommate.hub.dto.CreateReportDTO;
import com.roommate.hub.exception.ForbiddenException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest
@Transactional
class WorkflowRegressionIntegrationTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired MatchRequestRepository requests;
    @Autowired BlockedUserRepository blocks;
    @Autowired RoomPostRepository posts;
    @Autowired MatchRequestService matches;
    @Autowired MatchingService matching;
    @Autowired RoomPostService roomService;
    @Autowired AdminService admin;
    @Autowired ReportService reports;
    @Autowired ProfileService profileService;
    @Autowired ProfileController profile;
    @Autowired org.springframework.web.context.WebApplicationContext webContext;
    @Autowired org.springframework.security.web.FilterChainProxy securityFilterChain;

    @AfterEach void clearAuthentication() { SecurityContextHolder.clearContext(); }

    User user(String name) {
        return users.saveAndFlush(User.builder().email(name + UUID.randomUUID() + "@test.invalid")
                .passwordHash("not-a-real-password-hash").fullName(name).gender("MALE").role(User.Role.ROLE_USER).build());
    }
    void authenticate(User user) {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
    }
    UserPreference preference(User user) {
        return preferences.saveAndFlush(UserPreference.builder().user(user).targetDistrict("TEST_DISTRICT")
                .budgetAmount(2000000.0).budgetMin(1000000.0).budgetMax(3000000.0).targetGender("ANY")
                .sleepHabit(1).cleanlinessLevel(4).isSmoking(false).allowPets(false).build());
    }
    RoomPost post(User author) {
        return posts.saveAndFlush(RoomPost.builder().author(author).title("Test room").description("Test description")
                .price(2000000.0).address("Test address").maxOccupants(2).status(RoomPost.PostStatus.APPROVED).build());
    }

    @Test void reciprocalSendReusesRequestAndCanOnlyBeRespondedToOnce() {
        User a = user("A"), b = user("B");
        Long id = matches.sendRequest(a.getId(), b.getId()).getRequestId();
        com.roommate.hub.dto.MatchRequestResponseDTO reciprocal = matches.sendRequest(b.getId(), a.getId());
        assertThat(reciprocal.getRequestId()).isEqualTo(id);
        assertThat(reciprocal.getStatus()).isEqualTo(MatchRequest.MatchStatus.ACCEPTED.name());
        assertThat(requests.findAllBetweenUsers(a.getId(), b.getId())).hasSize(1);
        assertThat(requests.findById(id).orElseThrow().getStatus()).isEqualTo(MatchRequest.MatchStatus.ACCEPTED);
        assertThatThrownBy(() -> matches.respondRequest(id, true, b.getId())).isInstanceOf(IllegalArgumentException.class);
    }

    @Test void legacyReciprocalRowsDoNotCrashLookupAndCancelRemovesBoth() {
        User a = user("A"), b = user("B");
        requests.save(MatchRequest.builder().sender(a).receiver(b).matchScore(90.0).status(MatchRequest.MatchStatus.ACCEPTED).build());
        requests.save(MatchRequest.builder().sender(b).receiver(a).matchScore(90.0).status(MatchRequest.MatchStatus.PENDING).build());
        assertThat(requests.findConnectionBetweenUsers(a.getId(), b.getId()).orElseThrow().getStatus()).isEqualTo(MatchRequest.MatchStatus.ACCEPTED);
        matches.cancelConnection(a.getId(), b.getId());
        assertThat(requests.findAllBetweenUsers(a.getId(), b.getId())).isEmpty();
    }

    @Test void blockingPreventsConnectionsAndHidesPreviouslyUnlockedContact() {
        User a = user("A"), b = user("B");
        Long id = matches.sendRequest(a.getId(), b.getId()).getRequestId();
        matches.respondRequest(id, true, b.getId());
        blocks.saveAndFlush(BlockedUser.builder().user(b).blockedUser(a).build());
        assertThatThrownBy(() -> matches.sendRequest(a.getId(), b.getId())).isInstanceOf(ForbiddenException.class);
        assertThat(matches.getSentRequests(a.getId())).isEmpty();
        assertThat(matches.getReceivedRequests(b.getId())).isEmpty();
    }

    @Test void recommendationHonorsGenderPrivacyLockedStatusAndSmokingPriority() {
        User a = user("A"), b = user("B");
        b.setGender("FEMALE"); users.saveAndFlush(b);
        UserPreference ap = preference(a), bp = preference(b);
        assertThat(matching.getRecommendations(a)).extracting("userId").contains(b.getId());
        b.setSearchActive(false); users.saveAndFlush(b);
        assertThat(matching.getRecommendations(a)).isEmpty();
        b.setSearchActive(true); b.setStatus("LOCKED"); users.saveAndFlush(b);
        assertThat(matching.getRecommendations(a)).isEmpty();
        b.setStatus("ACTIVE"); users.saveAndFlush(b);
        ap.setTopPriority("SMOKING"); preferences.saveAndFlush(ap);
        bp.setIsSmoking(true); preferences.saveAndFlush(bp);
        assertThat(matching.getRecommendations(a)).isEmpty();
    }

    @Test void ownListingIncludesStatusAndModerationReasonAndSavesAreAccountScoped() {
        User a = user("A"), b = user("B");
        RoomPost p = post(a);
        authenticate(b);
        profile.setSavedPost(p.getId(), Map.of("saved", true));
        assertThat(profile.getSavedPosts()).containsExactly(p.getId());
        authenticate(a);
        assertThat(profile.getSavedPosts()).isEmpty();
        admin.moderatePost(p.getId(), "REJECTED", "Please correct the price");
        var dto = roomService.getMyPosts().getFirst();
        assertThat(dto.getStatus()).isEqualTo("REJECTED");
        assertThat(dto.getModerationReason()).isEqualTo("Please correct the price");
        assertThatThrownBy(() -> admin.moderatePost(p.getId(), "INVALID", null)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test void reportingRejectsInvalidOrMissingTargets() {
        User a = user("A"), b = user("B"); authenticate(a);
        var dto = CreateReportDTO.builder().targetId(b.getId()).targetType("USER").reason("Test report").build();
        assertThat(reports.createReport(dto).get("status")).isEqualTo("PENDING");
        dto.setTargetType("INVALID");
        assertThatThrownBy(() -> reports.createReport(dto)).isInstanceOf(IllegalArgumentException.class);
        dto.setTargetType("USER"); dto.setTargetId(a.getId());
        assertThatThrownBy(() -> reports.createReport(dto)).isInstanceOf(IllegalArgumentException.class);
        dto.setTargetId(Long.MAX_VALUE);
        assertThatThrownBy(() -> reports.createReport(dto)).isInstanceOf(com.roommate.hub.exception.ResourceNotFoundException.class);
    }

    @Test void missingAuthenticationReturns401SoClientCanRefresh() throws Exception {
        org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(webContext)
                .addFilters(securityFilterChain).build()
                .perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/v1/posts/my"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isUnauthorized());
    }

    @Test void budgetOverlapAndPriorityProduceRealScores() {
        User a = user("A"), b = user("B");
        UserPreference ap = preference(a), bp = preference(b);
        bp.setBudgetMin(2500000.0); bp.setBudgetMax(4000000.0); bp.setBudgetAmount(4000000.0);
        bp.setSleepHabit(3); preferences.saveAndFlush(bp);
        assertThat(matching.calculateCriteriaDetail(ap, bp).getBudgetMatch()).isEqualTo(100.0);
        double baseline = matching.getRecommendations(a).getFirst().getTotalScore();
        ap.setTopPriority("SLEEP"); preferences.saveAndFlush(ap);
        assertThat(matching.getRecommendations(a).getFirst().getTotalScore()).isLessThan(baseline);
    }

    @Test void publicProfileOnlyReturnsActiveSearchableUsers() {
        User candidate = user("Candidate");
        UserPreference pref = preference(candidate);
        pref.setBioDescription("Public bio");
        preferences.saveAndFlush(pref);

        var visible = profileService.getPublicProfile(candidate.getId());
        assertThat(visible.getUserId()).isEqualTo(candidate.getId());
        assertThat(visible.getFullName()).isEqualTo("Candidate");
        assertThat(visible.getBioDescription()).isEqualTo("Public bio");

        candidate.setSearchActive(false);
        users.saveAndFlush(candidate);
        assertThatThrownBy(() -> profileService.getPublicProfile(candidate.getId()))
                .isInstanceOf(com.roommate.hub.exception.ResourceNotFoundException.class);
    }
}
