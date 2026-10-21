package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.UUID;
import java.time.LocalDateTime;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class BlockPrivacyIntegrationTest {
    @Autowired UserRepository users;
    @Autowired MatchRequestRepository matches;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired JwtUtils jwtUtils;
    @Autowired WebApplicationContext webContext;
    @Autowired FilterChainProxy securityFilterChain;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(webContext).addFilters(securityFilterChain).build();
    }

    @AfterEach void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test void blockingStrangerAndListingNeverExposeContactAndUnblockStillWorks() throws Exception {
        User viewer = user("Viewer"), target = user("Target"), outsider = user("Outsider");

        assertSafeBlock(mvc.perform(post("/api/v1/blocks")
                .header("Authorization", bearer(viewer)).param("targetUserId", target.getId().toString())), target, "$");
        // Repeating the operation uses the existing-row path rather than creating a second block.
        assertSafeBlock(mvc.perform(post("/api/v1/blocks")
                .header("Authorization", bearer(viewer)).param("targetUserId", target.getId().toString())), target, "$");
        assertSafeBlock(mvc.perform(get("/api/v1/blocks").header("Authorization", bearer(viewer)))
                .andExpect(jsonPath("$", hasSize(1))), target, "$[0]");

        mvc.perform(get("/api/v1/blocks").header("Authorization", bearer(outsider)))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(0)));
        mvc.perform(delete("/api/v1/blocks/{id}", target.getId()).header("Authorization", bearer(viewer)))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/blocks").header("Authorization", bearer(viewer)))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(0)));
    }

    @Test void blockingPreviouslyConnectedUserDoesNotExposeContactEither() throws Exception {
        User viewer = user("Viewer"), target = user("Target");
        matches.saveAndFlush(MatchRequest.builder().sender(viewer).receiver(target)
                .matchScore(90.0).status(MatchRequest.MatchStatus.ACCEPTED).build());

        assertSafeBlock(mvc.perform(post("/api/v1/blocks")
                .header("Authorization", bearer(viewer)).param("targetUserId", target.getId().toString())), target, "$");
        assertSafeBlock(mvc.perform(get("/api/v1/blocks").header("Authorization", bearer(viewer))), target, "$[0]");
    }

    @Test void anonymousCallerCannotReadOrCreateBlocks() throws Exception {
        mvc.perform(get("/api/v1/blocks")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/blocks").param("targetUserId", "1")).andExpect(status().isUnauthorized());
    }

    private void assertSafeBlock(ResultActions response, User target, String path) throws Exception {
        response.andExpect(status().isOk())
                // An exact field count prevents accidentally exposing other User fields later.
                .andExpect(jsonPath(path + ".*", hasSize(5)))
                .andExpect(jsonPath(path + ".id").isNumber())
                .andExpect(jsonPath(path + ".blockedUserId").value(target.getId()))
                .andExpect(jsonPath(path + ".blockedUserName").value(target.getFullName()))
                .andExpect(jsonPath(path + ".blockedUserAvatar").value(target.getAvatarUrl()))
                .andExpect(jsonPath(path + ".createdAt").isNotEmpty())
                .andExpect(jsonPath(path + ".blockedUserEmail").doesNotExist())
                .andExpect(jsonPath(path + ".email").doesNotExist())
                .andExpect(jsonPath(path + ".phone").doesNotExist())
                .andExpect(jsonPath(path + ".passwordHash").doesNotExist());
    }

    private String bearer(User user) {
        RefreshToken grant = refreshTokens.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(7)).build());
        return "Bearer " + jwtUtils.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private User user(String name) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .passwordHash("test-only-placeholder").fullName(name).gender("MALE")
                .phone("0000000000").avatarUrl("https://example.invalid/avatar.png")
                .role(User.Role.ROLE_USER).build());
    }
}
