package com.roommate.hub.exception;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Test-only fault injection exercises the advice without a network, database or mocked success response.
class ApiExceptionHandlerTest {
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new FaultController())
                .setControllerAdvice(new ApiExceptionHandler()).build();
    }

    @Test void unexpectedRuntimeFailureIsGenericServerErrorNotClientError() throws Exception {
        String body = mvc.perform(get("/fault/runtime"))
                .andExpect(status().isInternalServerError()).andExpect(jsonPath("status").value(500))
                .andExpect(jsonPath("message").value("Đã xảy ra lỗi máy chủ"))
                .andExpect(jsonPath("$").value(hasKey("data"))).andExpect(jsonPath("data").value(nullValue()))
                .andExpect(jsonPath("timestamp").isNotEmpty()).andReturn().getResponse().getContentAsString();
        assertThat(body).doesNotContain("synthetic-secret", "select password_hash", "NullPointerException", "stackTrace");
    }

    @Test void unexpectedCheckedFailureAlsoReturnsGenericServerError() throws Exception {
        String body = mvc.perform(get("/fault/checked"))
                .andExpect(status().isInternalServerError()).andExpect(jsonPath("status").value(500))
                .andExpect(jsonPath("message").value("Đã xảy ra lỗi máy chủ"))
                .andReturn().getResponse().getContentAsString();
        assertThat(body).doesNotContain("synthetic-secret", "select password_hash", "Exception");
    }

    @Test void explicitForbiddenAndAuthenticationFailuresKeepTheirSecurityStatus() throws Exception {
        mvc.perform(get("/fault/access-denied"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("status").value(403));
        mvc.perform(get("/fault/authentication"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("status").value(401));
    }

    @Test void explicitServiceUnavailableIsNotConvertedToBadRequestOrUnexpected500() throws Exception {
        mvc.perform(get("/fault/unavailable"))
                .andExpect(status().isServiceUnavailable()).andExpect(jsonPath("status").value(503));
    }

    @Test void explicitInternalServerErrorAlsoSuppressesItsTechnicalReason() throws Exception {
        String body = mvc.perform(get("/fault/explicit-internal"))
                .andExpect(status().isInternalServerError()).andExpect(jsonPath("status").value(500))
                .andExpect(jsonPath("message").value("Đã xảy ra lỗi máy chủ"))
                .andReturn().getResponse().getContentAsString();
        assertThat(body).doesNotContain("synthetic-secret", "select password_hash");
    }

    @Test void knownBusinessValidationKeepsReadable400Message() throws Exception {
        mvc.perform(get("/fault/bad-request"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400))
                .andExpect(jsonPath("message").value("Trạng thái kiểm duyệt không hợp lệ"));
    }

    @RestController
    static class FaultController {
        @GetMapping("/fault/optimistic") String optimistic() {
            throw new org.springframework.dao.OptimisticLockingFailureException("synthetic-secret: SQL update details");
        }

        @GetMapping("/fault/jpa-optimistic") String jpaOptimistic() {
            throw new jakarta.persistence.OptimisticLockException("synthetic-secret: SQL update details");
        }
        @GetMapping("/fault/runtime") String runtime() {
            throw new NullPointerException("synthetic-secret: select password_hash from users");
        }

        @GetMapping("/fault/checked") String checked() throws Exception {
            throw new Exception("synthetic-secret: select password_hash from users");
        }

        @GetMapping("/fault/access-denied") String forbidden() {
            throw new AccessDeniedException("Forbidden");
        }

        @GetMapping("/fault/authentication") String authentication() {
            throw new BadCredentialsException("Synthetic credentials detail");
        }

        @GetMapping("/fault/unavailable") String unavailable() {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Dịch vụ lưu trữ tạm thời không khả dụng");
        }

        @GetMapping("/fault/explicit-internal") String explicitInternal() {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "synthetic-secret: select password_hash from users");
        }

        @GetMapping("/fault/bad-request") String validation() {
            throw new IllegalArgumentException("Trạng thái kiểm duyệt không hợp lệ");
        }
    }

    @Test void concurrentUpdateIs409WithoutLeakingTechnicalDetails() throws Exception {
        for (String path : new String[]{"/fault/optimistic", "/fault/jpa-optimistic"}) {
            String body = mvc.perform(get(path)).andExpect(status().isConflict())
                    .andExpect(jsonPath("status").value(409)).andExpect(jsonPath("message").isNotEmpty())
                    .andReturn().getResponse().getContentAsString();
            assertThat(body).doesNotContain("synthetic-secret", "SQL", "Exception");
        }
    }
}
