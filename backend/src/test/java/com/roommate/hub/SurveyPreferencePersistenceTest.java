package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class SurveyPreferencePersistenceTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired EntityManager em;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    MockMvc mvc;
    Long ownerId;
    String authorization;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        User owner = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Survey owner").passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
        ownerId = owner.getId();
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(owner)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        authorization = "Bearer " + jwt.generateToken(owner.getEmail(), ownerId, grant.getId());
    }

    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void fourFieldsPersistAndReloadFromDatabase() throws Exception {
        putBody(extra("2099-11-04", "PRIVATE", "NIGHT", "SCHEDULE"), 200);
        em.flush(); em.clear();
        var pref = preferences.findByUserId(ownerId).orElseThrow();
        assertThat(pref.getMoveInDate()).isEqualTo(LocalDate.of(2099, 11, 4));
        assertThat(pref.getRoomType()).isEqualTo("PRIVATE");
        assertThat(pref.getWorkSchedule()).isEqualTo("NIGHT");
        assertThat(pref.getPersonalValue()).isEqualTo("SCHEDULE");
        read().andExpect(jsonPath("$.moveInDate").value("2099-11-04"))
                .andExpect(jsonPath("$.roomType").value("PRIVATE"))
                .andExpect(jsonPath("$.workSchedule").value("NIGHT"))
                .andExpect(jsonPath("$.personalValue").value("SCHEDULE"))
                .andExpect(jsonPath("$.topPriority").value("BUDGET"))
                .andExpect(jsonPath("$.bioDescription").value("Legacy metadata and note"));
    }

    @Test void editsReplaceChoicesRatherThanRetainingOriginalValues() throws Exception {
        putBody(extra("2099-11-04", "PRIVATE", "NIGHT", "SCHEDULE"), 200);
        putBody(extra("2099-12-05", "SHARED", "DAY", "PRIVACY"), 200);
        em.flush(); em.clear();
        read().andExpect(jsonPath("$.moveInDate").value("2099-12-05"))
                .andExpect(jsonPath("$.roomType").value("SHARED"))
                .andExpect(jsonPath("$.workSchedule").value("DAY"))
                .andExpect(jsonPath("$.personalValue").value("PRIVACY"));
        putBody(extra("2099-12-05", "SHARED", "DAY", "CLEAN"), 200);
        read().andExpect(jsonPath("$.personalValue").value("CLEAN"))
                .andExpect(jsonPath("$.topPriority").value("BUDGET"));
    }

    @Test void omittedOrNullFieldsFromOldClientsDoNotEraseNewChoices() throws Exception {
        putBody(extra("2099-11-04", "PRIVATE", "NIGHT", "SCHEDULE"), 200);
        for (String fields : new String[]{"", ",\"moveInDate\":null,\"roomType\":null,\"workSchedule\":null,\"personalValue\":null"}) {
            mvc.perform(put("/api/v1/profile/preferences/{id}", ownerId)
                    .header("Authorization", authorization).contentType(MediaType.APPLICATION_JSON).content(body(fields)))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.roomType").value("PRIVATE"))
                    .andExpect(jsonPath("$.moveInDate").value("2099-11-04"))
                    .andExpect(jsonPath("$.workSchedule").value("NIGHT"))
                    .andExpect(jsonPath("$.personalValue").value("SCHEDULE"));
            em.flush(); em.clear();
        }
    }

    @Test void legacyProfilesStayNullWithoutInventedDefaults() throws Exception {
        putBody("", 200);
        em.flush(); em.clear();
        var pref = preferences.findByUserId(ownerId).orElseThrow();
        assertThat(pref.getMoveInDate()).isNull();
        assertThat(pref.getRoomType()).isNull();
        assertThat(pref.getWorkSchedule()).isNull();
        assertThat(pref.getPersonalValue()).isNull();
        read().andExpect(jsonPath("$.moveInDate").isEmpty())
                .andExpect(jsonPath("$.roomType").isEmpty())
                .andExpect(jsonPath("$.workSchedule").isEmpty())
                .andExpect(jsonPath("$.personalValue").isEmpty());
    }

    @Test void invalidChoicesAreRejectedWithoutPartiallyChangingExistingPreferences() throws Exception {
        putBody(extra("2099-11-04", "PRIVATE", "NIGHT", "SCHEDULE"), 200);
        for (String fields : new String[]{",\"roomType\":\"OTHER\"", ",\"roomType\":\"\"",
                ",\"workSchedule\":\"day\"", ",\"workSchedule\":\"\"",
                ",\"personalValue\":\"BUDGET\"", ",\"personalValue\":\"\""}) {
            putBody(fields + ",\"moveInDate\":\"2099-12-05\"", 400);
            em.flush(); em.clear();
            read().andExpect(jsonPath("$.moveInDate").value("2099-11-04"))
                    .andExpect(jsonPath("$.roomType").value("PRIVATE"))
                    .andExpect(jsonPath("$.workSchedule").value("NIGHT"))
                    .andExpect(jsonPath("$.personalValue").value("SCHEDULE"));
        }
    }

    @Test void malformedDatesAndWrongJsonTypesReturn400WithoutSaving() throws Exception {
        for (String value : new String[]{"\"2026-02-30\"", "\"not-a-date\"", "\"2099-11-04T12:00:00Z\"", "{}"}) {
            putBody(",\"moveInDate\":" + value, 400);
            assertThat(preferences.findByUserId(ownerId)).isEmpty();
        }
        putBody(",\"roomType\":{}", 400);
    }

    @Test void validPastDateIsRetainedAsHistoricalUserChoice() throws Exception {
        putBody(extra("2020-01-01", "SHARED", "DAY", "CLEAN"), 200);
        em.flush(); em.clear();
        read().andExpect(jsonPath("$.moveInDate").value("2020-01-01"));
    }

    @Test void biographyEditDoesNotEraseStructuredSurveyChoices() throws Exception {
        putBody(extra("2099-11-04", "PRIVATE", "NIGHT", "SCHEDULE"), 200);
        mvc.perform(put("/api/v1/profile/user/{id}", ownerId).header("Authorization", authorization)
                .param("fullName", "Survey owner").param("phone", "").param("gender", "MALE")
                .param("bioNote", "Edited note")).andExpect(status().isOk());
        em.flush(); em.clear();
        read().andExpect(jsonPath("$.bioDescription").value("Edited note"))
                .andExpect(jsonPath("$.moveInDate").value("2099-11-04"))
                .andExpect(jsonPath("$.roomType").value("PRIVATE"))
                .andExpect(jsonPath("$.workSchedule").value("NIGHT"))
                .andExpect(jsonPath("$.personalValue").value("SCHEDULE"));
    }

    @Test void otherUserCannotReadOrWriteOwnersSurvey() throws Exception {
        User other = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Other").passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
        mvc.perform(put("/api/v1/profile/preferences/{id}", other.getId()).header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body(extra("2099-11-04", "SHARED", "DAY", "CLEAN"))))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/profile/preferences/{id}", other.getId()).header("Authorization", authorization))
                .andExpect(status().isForbidden());
        assertThat(preferences.findByUserId(other.getId())).isEmpty();
    }

    private org.springframework.test.web.servlet.ResultActions read() throws Exception {
        return mvc.perform(get("/api/v1/profile/preferences/{id}", ownerId)
                .header("Authorization", authorization)).andExpect(status().isOk());
    }
    private void putBody(String fields, int code) throws Exception {
        mvc.perform(put("/api/v1/profile/preferences/{id}", ownerId).header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body(fields)))
                .andExpect(result -> assertThat(result.getResponse().getStatus()).as("Input %s", fields).isEqualTo(code));
    }
    private String body(String fields) {
        return "{\"targetDistrict\":\"Thu Duc\",\"budgetAmount\":3000000,\"budgetMin\":1000000,\"budgetMax\":4000000,"
                + "\"sleepHabit\":2,\"cleanlinessLevel\":4,\"isSmoking\":false,\"allowPets\":false,"
                + "\"topPriority\":\"BUDGET\",\"bioDescription\":\"Legacy metadata and note\"" + fields + "}";
    }
    private String extra(String date, String room, String work, String personal) {
        return ",\"moveInDate\":\"" + date + "\",\"roomType\":\"" + room + "\",\"workSchedule\":\""
                + work + "\",\"personalValue\":\"" + personal + "\"";
    }
}
