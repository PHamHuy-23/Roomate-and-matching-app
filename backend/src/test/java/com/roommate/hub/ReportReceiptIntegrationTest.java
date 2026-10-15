package com.roommate.hub;

import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.ReportRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.config.JwtUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.http.MediaType;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class ReportReceiptIntegrationTest {
    @Autowired UserRepository users;
    @Autowired ReportRepository reports;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }
    @AfterEach void clearAuthentication() { SecurityContextHolder.clearContext(); }

    @Test void submissionReturnsDistinctPersistedIdsAndPendingStatus() throws Exception {
        User reporter = user(User.Role.ROLE_USER), target = user(User.Role.ROLE_USER);
        String auth = bearer(reporter);
        long count = reports.count();
        long first = submit(auth, target.getId());
        long second = submit(auth, target.getId());
        assertThat(first).isNotEqualTo(second);
        assertThat(reports.count()).isEqualTo(count + 2);
        assertThat(reports.findAll().stream()
                .filter(report -> report.getReporter().getId().equals(reporter.getId()))
                .map(com.roommate.hub.entity.Report::getId).toList()).containsExactlyInAnyOrder(first, second);
        for (long id : new long[]{first, second}) {
            var saved = reports.findById(id).orElseThrow();
            assertThat(saved.getStatus()).isEqualTo("PENDING");
            assertThat(saved.getTargetId()).isEqualTo(target.getId());
            assertThat(saved.getReason()).isEqualTo("Test report receipt");
            assertThat(saved.getActionNote()).isNull();
        }
    }

    @Test void missingTargetDoesNotCreateReportOrReceipt() throws Exception {
        String auth = bearer(user(User.Role.ROLE_USER));
        long count = reports.count();
        mvc.perform(post("/api/v1/reports").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"Test reason\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("reportId").doesNotExist());
        assertThat(reports.count()).isEqualTo(count);
    }

    @Test void adminResponseConfirmsActualIdStatusAndNoteWithoutHidingHistory() throws Exception {
        User reporter = user(User.Role.ROLE_USER), target = user(User.Role.ROLE_USER);
        submit(bearer(reporter), target.getId());
        var saved = reports.findAll().stream()
                .filter(report -> report.getReporter().getId().equals(reporter.getId())).findFirst().orElseThrow();
        String adminAuth = bearer(user(User.Role.ROLE_ADMIN));
        mvc.perform(put("/api/v1/admin/reports/{id}/moderate", saved.getId())
                        .header("Authorization", adminAuth).param("status", "RESOLVED").param("note", "Verified test note"))
                .andExpect(status().isOk()).andExpect(jsonPath("id").value(saved.getId()))
                .andExpect(jsonPath("status").value("RESOLVED"))
                .andExpect(jsonPath("actionNote").value("Verified test note"));
        mvc.perform(get("/api/v1/admin/reports").header("Authorization", adminAuth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + saved.getId() + ")].status").value(org.hamcrest.Matchers.contains("RESOLVED")));
        mvc.perform(get("/api/v1/admin/reports").header("Authorization", bearer(reporter)))
                .andExpect(status().isForbidden());
        assertThat(reports.findById(saved.getId()).orElseThrow().getActionNote()).isEqualTo("Verified test note");
    }

    private long submit(String auth, Long targetId) throws Exception {
        String body = mvc.perform(post("/api/v1/reports").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetId\":" + targetId + ",\"targetType\":\"USER\",\"reason\":\"Test report receipt\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("reportId").isNumber())
                .andExpect(jsonPath("status").value("PENDING")).andReturn().getResponse().getContentAsString();
        return ((Number) com.jayway.jsonpath.JsonPath.read(body, "$.reportId")).longValue();
    }
    private User user(User.Role role) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Test user").passwordHash("test-only-placeholder").gender("OTHER").role(role).build());
    }
    private String bearer(User user) {
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(user)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }
}
