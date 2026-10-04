package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class PublicProfileBlockIntegrationTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired MatchRequestRepository matches;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }

    @AfterEach void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test void visibleProfileContainsOnlyPublicFieldsEvenAfterAcceptedConnection() throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        connect(viewer, target);

        assertPublicProfile(profile(viewer, target), target);
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void blockInEitherDirectionDeniesProfileEvenAfterAcceptedConnection(boolean reverseBlock) throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        connect(viewer, target);
        block(reverseBlock ? target : viewer, reverseBlock ? viewer : target);

        assertDeniedWithoutProfile(profile(viewer, target));
    }

    @Test void unblockingRestoresProfileOnlyAfterBothDirectionsAreUnblocked() throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        assertPublicProfile(profile(viewer, target), target);
        block(viewer, target);
        assertDeniedWithoutProfile(profile(viewer, target));
        block(target, viewer);

        unblock(viewer, target);
        assertDeniedWithoutProfile(profile(viewer, target));
        assertDeniedWithoutProfile(profile(target, viewer));

        unblock(target, viewer);
        assertPublicProfile(profile(viewer, target), target);
        assertPublicProfile(profile(target, viewer), viewer);
    }

    @Test void unrelatedBlockDoesNotHideAnotherVisibleProfile() throws Exception {
        User viewer = user("Viewer"), target = user("Target"), outsider = user("Outsider");
        block(viewer, outsider);
        block(outsider, target);

        assertPublicProfile(profile(viewer, target), target);
    }

    @Test void adminDoesNotBypassBlocksOnPublicProfileApi() throws Exception {
        User admin = user("Admin"), target = user("Target");
        admin.setRole(User.Role.ROLE_ADMIN);
        users.saveAndFlush(admin);
        block(target, admin);

        assertDeniedWithoutProfile(profile(admin, target));
    }

    @ParameterizedTest
    @ValueSource(strings = {"LOCKED", "HIDDEN"})
    void lockedOrHiddenTargetRemainsNotFoundEvenWhenBlocked(String state) throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        block(viewer, target);
        if ("LOCKED".equals(state)) target.setStatus("LOCKED");
        else target.setSearchActive(false);
        users.saveAndFlush(target);

        profile(viewer, target).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.userId").doesNotExist())
                .andExpect(jsonPath("$.fullName").doesNotExist())
                .andExpect(jsonPath("$.phone").doesNotExist())
                .andExpect(jsonPath("$.email").doesNotExist());
    }

    @Test void nonexistentProfileRemainsNotFound() throws Exception {
        User viewer = user("Viewer");
        mvc.perform(get("/api/v1/profile/public/{id}", Long.MAX_VALUE)
                        .header("Authorization", bearer(viewer)))
                .andExpect(status().isNotFound());
    }

    @Test void anonymousCallerCannotReadPublicProfile() throws Exception {
        User target = user("Target");
        mvc.perform(get("/api/v1/profile/public/{id}", target.getId()))
                .andExpect(status().isUnauthorized());
    }

    @Test void lockedCallerCannotUsePreviouslyIssuedTokenToReadProfile() throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        String authorization = bearer(viewer);
        viewer.setStatus("LOCKED");
        users.saveAndFlush(viewer);

        mvc.perform(get("/api/v1/profile/public/{id}", target.getId())
                        .header("Authorization", authorization))
                .andExpect(status().isUnauthorized());
    }

    @Test void visibleSelfProfileStillWorksWithoutExposingPrivateFields() throws Exception {
        User viewer = user("Viewer");
        assertPublicProfile(profile(viewer, viewer), viewer);
    }

    private ResultActions profile(User viewer, User target) throws Exception {
        return mvc.perform(get("/api/v1/profile/public/{id}", target.getId())
                .header("Authorization", bearer(viewer)));
    }

    private void block(User viewer, User target) throws Exception {
        mvc.perform(post("/api/v1/blocks").header("Authorization", bearer(viewer))
                        .param("targetUserId", target.getId().toString()))
                .andExpect(status().isOk());
    }

    private void unblock(User viewer, User target) throws Exception {
        mvc.perform(delete("/api/v1/blocks/{id}", target.getId())
                        .header("Authorization", bearer(viewer)))
                .andExpect(status().isOk());
    }

    private void assertDeniedWithoutProfile(ResultActions response) throws Exception {
        response.andExpect(status().isForbidden())
                .andExpect(jsonPath("$.userId").doesNotExist())
                .andExpect(jsonPath("$.fullName").doesNotExist())
                .andExpect(jsonPath("$.avatarUrl").doesNotExist())
                .andExpect(jsonPath("$.university").doesNotExist())
                .andExpect(jsonPath("$.targetDistrict").doesNotExist())
                .andExpect(jsonPath("$.budgetMin").doesNotExist())
                .andExpect(jsonPath("$.budgetMax").doesNotExist())
                .andExpect(jsonPath("$.sleepHabit").doesNotExist())
                .andExpect(jsonPath("$.cleanlinessLevel").doesNotExist())
                .andExpect(jsonPath("$.isSmoking").doesNotExist())
                .andExpect(jsonPath("$.allowPets").doesNotExist())
                .andExpect(jsonPath("$.bioDescription").doesNotExist())
                .andExpect(jsonPath("$.phone").doesNotExist())
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    private void assertPublicProfile(ResultActions response, User target) throws Exception {
        response.andExpect(status().isOk())
                .andExpect(jsonPath("$.*", hasSize(12)))
                .andExpect(jsonPath("$.userId").value(target.getId()))
                .andExpect(jsonPath("$.fullName").value(target.getFullName()))
                .andExpect(jsonPath("$.avatarUrl").value(target.getAvatarUrl()))
                .andExpect(jsonPath("$.university").value(target.getUniversity()))
                .andExpect(jsonPath("$.targetDistrict").value("Thu Duc"))
                .andExpect(jsonPath("$.budgetMin").value(2000000.0))
                .andExpect(jsonPath("$.budgetMax").value(4000000.0))
                .andExpect(jsonPath("$.sleepHabit").value(2))
                .andExpect(jsonPath("$.cleanlinessLevel").value(4))
                .andExpect(jsonPath("$.isSmoking").value(false))
                .andExpect(jsonPath("$.allowPets").value(true))
                .andExpect(jsonPath("$.bioDescription").value("Public biography"))
                .andExpect(jsonPath("$.phone").doesNotExist())
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.birthDate").doesNotExist())
                .andExpect(jsonPath("$.createdAt").doesNotExist())
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andExpect(jsonPath("$.role").doesNotExist())
                .andExpect(jsonPath("$.status").doesNotExist());
    }

    private void connect(User viewer, User target) {
        matches.saveAndFlush(MatchRequest.builder().sender(viewer).receiver(target)
                .status(MatchRequest.MatchStatus.ACCEPTED).matchScore(90.0).build());
    }

    private String bearer(User user) {
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private User user(String name) {
        User user = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE")
                .phone("0000000000").avatarUrl("https://example.invalid/avatar.png")
                .university("Test university").birthDate(LocalDate.of(2000, 1, 1))
                .role(User.Role.ROLE_USER).build());
        preferences.saveAndFlush(UserPreference.builder().user(user).targetDistrict("Thu Duc")
                .budgetAmount(3000000.0).budgetMin(2000000.0).budgetMax(4000000.0)
                .sleepHabit(2).cleanlinessLevel(4).isSmoking(false).allowPets(true)
                .bioDescription("Public biography").build());
        return user;
    }
}
