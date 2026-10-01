package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AdminUserDataIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }
    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void adminListAndDetailReturnActualProfileAndCreationDateWithoutSecrets() throws Exception {
        User admin = user(User.Role.ROLE_ADMIN), target = user(User.Role.ROLE_USER);
        target.setPhone("0000000000");
        target.setGender("FEMALE");
        target.setUniversity("Test university");
        target.setBirthDate(LocalDate.of(2002, 4, 12));
        users.saveAndFlush(target);
        String authorization = bearer(admin);
        var detail = mvc.perform(get("/api/v1/admin/users/{id}", target.getId()).header("Authorization", authorization));
        assertProfile(detail, "$", target);
        var list = mvc.perform(get("/api/v1/admin/users").header("Authorization", authorization));
        assertProfile(list, "$[?(@.id == " + target.getId() + ")]", target);
    }

    @Test void optionalMissingProfileFieldsStayNullInsteadOfInventedValues() throws Exception {
        User admin = user(User.Role.ROLE_ADMIN), target = user(User.Role.ROLE_USER);
        mvc.perform(get("/api/v1/admin/users/{id}", target.getId()).header("Authorization", bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.phone").isEmpty())
                .andExpect(jsonPath("$.university").isEmpty())
                .andExpect(jsonPath("$.birthDate").isEmpty())
                .andExpect(jsonPath("$.createdAt").isNotEmpty());
    }

    @Test void ordinaryAndAnonymousCallersCannotReadAdminProfiles() throws Exception {
        User target = user(User.Role.ROLE_USER), viewer = user(User.Role.ROLE_USER);
        String authorization = bearer(viewer);
        mvc.perform(get("/api/v1/admin/users").header("Authorization", authorization)).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/users/{id}", target.getId()).header("Authorization", authorization))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/users/{id}", target.getId())).andExpect(status().isUnauthorized());
    }

    @Test void publicProfileStillDoesNotExposeContactOrPrivateAccountFields() throws Exception {
        User target = user(User.Role.ROLE_USER), viewer = user(User.Role.ROLE_USER);
        target.setPhone("0000000000");
        users.saveAndFlush(target);
        mvc.perform(get("/api/v1/profile/public/{id}", target.getId()).header("Authorization", bearer(viewer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.phone").doesNotExist()).andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.createdAt").doesNotExist()).andExpect(jsonPath("$.birthDate").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    private void assertProfile(ResultActions result, String path, User target) throws Exception {
        result.andExpect(status().isOk())
                .andExpect(jsonPath(path + ".phone").value(target.getPhone()))
                .andExpect(jsonPath(path + ".gender").value(target.getGender()))
                .andExpect(jsonPath(path + ".university").value(target.getUniversity()))
                .andExpect(jsonPath(path + ".birthDate").value("2002-04-12"))
                .andExpect(jsonPath(path + ".createdAt").isNotEmpty())
                .andExpect(jsonPath(path + ".passwordHash").doesNotExist())
                .andExpect(jsonPath(path + ".passwordChangedAt").doesNotExist())
                .andExpect(jsonPath(path + ".refreshToken").doesNotExist())
                .andExpect(jsonPath(path + ".loggedOutAt").doesNotExist());
    }

    private User user(User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Test account").passwordHash("test-only-placeholder").gender("MALE").role(role).build());
    }

    private String bearer(User user) {
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(user).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(7)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }
}
