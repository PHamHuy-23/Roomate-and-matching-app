package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class AdminUserStatusIntegrationTest {
    @Autowired UserRepository users;
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

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void repeatedLockAndUnlockKeepTheExplicitTargetAcrossEveryAlias(String method, String suffix) throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), target = user("Target", User.Role.ROLE_USER);
        String authorization = bearer(admin);
        long userCount = users.count();

        assertStatus(setStatus(method, suffix, target.getId(), authorization, "LOCKED"), target, "LOCKED");
        assertStatus(setStatus(method, suffix, target.getId(), authorization, "LOCKED"), target, "LOCKED");
        assertStatus(setStatus(method, suffix, target.getId(), authorization, "ACTIVE"), target, "ACTIVE");
        assertStatus(setStatus(method, suffix, target.getId(), authorization, "ACTIVE"), target, "ACTIVE");

        assertThat(users.count()).isEqualTo(userCount);
        assertThat(users.findById(admin.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void staleLockAndUnlockIntentsDoNotInvertAnotherAdminsAction(String method, String suffix) throws Exception {
        User firstAdmin = user("First admin", User.Role.ROLE_ADMIN);
        User secondAdmin = user("Second admin", User.Role.ROLE_ADMIN);
        User target = user("Target", User.Role.ROLE_USER);
        String firstAuthorization = bearer(firstAdmin), secondAuthorization = bearer(secondAdmin);

        // Both administrators saw ACTIVE before the first lock. The delayed lock must not unlock it.
        assertStatus(setStatus("PUT", "status", target.getId(), firstAuthorization, "LOCKED"), target, "LOCKED");
        assertStatus(setStatus(method, suffix, target.getId(), secondAuthorization, "LOCKED"), target, "LOCKED");

        // Both saw LOCKED before the first unlock. A delayed unlock must not lock it again.
        assertStatus(setStatus("PATCH", "status", target.getId(), firstAuthorization, "ACTIVE"), target, "ACTIVE");
        assertStatus(setStatus(method, suffix, target.getId(), secondAuthorization, "ACTIVE"), target, "ACTIVE");
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void malformedMissingAndUnsupportedStatusesNeverMutateEitherCurrentState(String method, String suffix) throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), target = user("Target", User.Role.ROLE_USER);
        String authorization = bearer(admin);
        long userCount = users.count();
        String[] invalidBodies = {null, "{}", "null", "{\"status\":null}", "{\"status\":\"\"}",
                "{\"status\":\"   \"}", "{\"status\":\"BLOCKED\"}", "{\"status\":\"UNKNOWN\"}",
                "{\"status\":\"locked\"}", "{\"status\":\"active\"}", "{\"status\":\" LOCKED \"}",
                "{\"status\":123}", "{\"status\":true}", "{\"status\":{}}", "{\"status\":"};

        for (String currentStatus : new String[]{"ACTIVE", "LOCKED"}) {
            target.setStatus(currentStatus);
            users.saveAndFlush(target);
            for (String body : invalidBodies) {
                send(method, suffix, target.getId(), authorization, body).andExpect(status().isBadRequest());
                assertThat(users.findById(target.getId()).orElseThrow().getStatus()).isEqualTo(currentStatus);
                assertThat(users.count()).isEqualTo(userCount);
            }
            // A query parameter cannot silently restore the old, bodyless toggle contract.
            mvc.perform(builder(method, suffix, target.getId(), authorization, null).param("status", "LOCKED"))
                    .andExpect(status().isBadRequest());
            assertThat(users.findById(target.getId()).orElseThrow().getStatus()).isEqualTo(currentStatus);
        }
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void anonymousAndOrdinaryUsersCannotChangeAccountStatus(String method, String suffix) throws Exception {
        User caller = user("Ordinary user", User.Role.ROLE_USER), target = user("Target", User.Role.ROLE_USER);
        long userCount = users.count();
        for (String desiredStatus : new String[]{"LOCKED", "ACTIVE"}) {
            setStatus(method, suffix, target.getId(), null, desiredStatus).andExpect(status().isUnauthorized());
            setStatus(method, suffix, target.getId(), bearer(caller), desiredStatus).andExpect(status().isForbidden());
            assertThat(users.findById(target.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
        }
        assertThat(users.count()).isEqualTo(userCount);
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void lockedAdminCannotUsePreviouslyIssuedJwtToChangeAnotherAccount(String method, String suffix) throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN), target = user("Target", User.Role.ROLE_USER);
        String authorization = bearer(admin);
        admin.setStatus("LOCKED");
        users.saveAndFlush(admin);

        for (String desiredStatus : new String[]{"LOCKED", "ACTIVE"}) {
            setStatus(method, suffix, target.getId(), authorization, desiredStatus).andExpect(status().isUnauthorized());
            assertThat(users.findById(target.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
            assertThat(users.findById(admin.getId()).orElseThrow().getStatus()).isEqualTo("LOCKED");
        }
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void selfStatusUpdatesAreForbiddenEvenForSameActiveTarget(String method, String suffix) throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN);
        String authorization = bearer(admin);

        for (String desiredStatus : new String[]{"LOCKED", "ACTIVE"}) {
            setStatus(method, suffix, admin.getId(), authorization, desiredStatus).andExpect(status().isForbidden());
            assertThat(users.findById(admin.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
        }
    }

    @ParameterizedTest
    @CsvSource({"PUT,status", "PATCH,status", "PUT,toggle-status", "PATCH,toggle-status"})
    void missingTargetReturnsNotFoundWithoutCreatingAnAccount(String method, String suffix) throws Exception {
        User admin = user("Admin", User.Role.ROLE_ADMIN);
        String authorization = bearer(admin);
        long userCount = users.count();

        for (String desiredStatus : new String[]{"LOCKED", "ACTIVE"}) {
            setStatus(method, suffix, Long.MAX_VALUE, authorization, desiredStatus).andExpect(status().isNotFound());
            assertThat(users.count()).isEqualTo(userCount);
            assertThat(users.findById(admin.getId()).orElseThrow().getStatus()).isEqualTo("ACTIVE");
        }
    }

    private void assertStatus(ResultActions response, User target, String expectedStatus) throws Exception {
        response.andExpect(status().isOk())
                .andExpect(jsonPath("$.*", hasSize(2)))
                .andExpect(jsonPath("$.userId").value(target.getId()))
                .andExpect(jsonPath("$.status").value(expectedStatus));
        users.flush();
        assertThat(users.findById(target.getId()).orElseThrow().getStatus()).isEqualTo(expectedStatus);
    }

    private ResultActions setStatus(String method, String suffix, Long userId, String authorization, String desiredStatus)
            throws Exception {
        return send(method, suffix, userId, authorization, "{\"status\":\"" + desiredStatus + "\"}");
    }

    private ResultActions send(String method, String suffix, Long userId, String authorization, String body)
            throws Exception {
        return mvc.perform(builder(method, suffix, userId, authorization, body));
    }

    private MockHttpServletRequestBuilder builder(String method, String suffix, Long userId, String authorization, String body) {
        MockHttpServletRequestBuilder request = request(HttpMethod.valueOf(method),
                "/api/v1/admin/users/" + userId + "/" + suffix);
        if (authorization != null) request.header("Authorization", authorization);
        if (body != null) request.contentType(MediaType.APPLICATION_JSON).content(body);
        return request;
    }

    private String bearer(User user) {
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private User user(String name, User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName(name).passwordHash("test-only-placeholder").gender("MALE").role(role).build());
    }
}
