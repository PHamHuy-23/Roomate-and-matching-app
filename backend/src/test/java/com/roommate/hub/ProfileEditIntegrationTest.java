package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class ProfileEditIntegrationTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    MockMvc mvc;
    User owner;
    String authorization;
    static final String HEADER = "[Yêu cầu giới tính: Nam | Sở thích: Đọc sách | Ưu tiên: Ngân sách phù hợp]";

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        owner = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Original name").passwordHash("test-only-placeholder").gender("MALE")
                .university("Original university").role(User.Role.ROLE_USER).build());
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(owner)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        authorization = "Bearer " + jwt.generateToken(owner.getEmail(), owner.getId(), grant.getId());
    }
    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void savesBiographyPreservingSurveyMetadataAndAllCriteria() throws Exception {
        UserPreference pref = createPreference(HEADER + "\nOld note");
        mvc.perform(update().param("bioNote", "  New note\nSecond line  "))
                .andExpect(status().isOk()).andExpect(jsonPath("fullName").value("Updated name"));
        preferences.flush();
        assertThat(pref.getBioDescription()).isEqualTo(HEADER + "\nNew note\nSecond line");
        assertCriteriaUnchanged(pref);
        mvc.perform(get("/api/v1/profile/preferences/{id}", owner.getId()).header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("bioDescription").value(pref.getBioDescription()));
        mvc.perform(get("/api/v1/profile/public/{id}", owner.getId()).header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("bioDescription").value(pref.getBioDescription()));
    }

    @Test void clearingBiographyKeepsSurveyHeader() throws Exception {
        UserPreference pref = createPreference(HEADER + "\nOld note");
        mvc.perform(update().param("bioNote", "  ")).andExpect(status().isOk());
        assertThat(pref.getBioDescription()).isEqualTo(HEADER);
        assertCriteriaUnchanged(pref);
    }

    @Test void plainAndEmptyBiographiesCanBeEdited() throws Exception {
        UserPreference pref = createPreference("Plain note without survey metadata");
        mvc.perform(update().param("bioNote", "New note")).andExpect(status().isOk());
        assertThat(pref.getBioDescription()).isEqualTo("New note");
        pref.setBioDescription(null);
        mvc.perform(update().param("bioNote", "Another note")).andExpect(status().isOk());
        assertThat(pref.getBioDescription()).isEqualTo("Another note");
    }

    @Test void omittedBirthdayAndBiographyRemainUnchangedIncludingNullBirthday() throws Exception {
        UserPreference pref = createPreference(HEADER + "\nOld note");
        mvc.perform(update()).andExpect(status().isOk());
        assertThat(owner.getBirthDate()).isNull();
        assertThat(pref.getBioDescription()).isEqualTo(HEADER + "\nOld note");
        owner.setBirthDate(LocalDate.of(2002, 5, 20));
        mvc.perform(update()).andExpect(status().isOk()).andExpect(jsonPath("birthDate").value("2002-05-20"));
        assertThat(owner.getBirthDate()).isEqualTo(LocalDate.of(2002, 5, 20));
    }

    @Test void invalidBirthdayRejectsWholeUpdate() throws Exception {
        UserPreference pref = createPreference(HEADER + "\nOld note");
        mvc.perform(update().param("bioNote", "New note").param("birthDate", LocalDate.now().minusYears(17).toString()))
                .andExpect(status().isBadRequest());
        assertThat(owner.getFullName()).isEqualTo("Original name");
        assertThat(owner.getUniversity()).isEqualTo("Original university");
        assertThat(pref.getBioDescription()).isEqualTo(HEADER + "\nOld note");
    }

    @Test void validBirthdayCanStillBeUpdatedAtEighteenYearBoundary() throws Exception {
        LocalDate date = LocalDate.now().minusYears(18);
        mvc.perform(update().param("birthDate", date.toString()).param("university", "  Updated university  "))
                .andExpect(status().isOk()).andExpect(jsonPath("birthDate").value(date.toString()))
                .andExpect(jsonPath("university").value("Updated university"));
        assertThat(owner.getBirthDate()).isEqualTo(date);
        assertThat(owner.getUniversity()).isEqualTo("Updated university");
    }

    @Test void invalidUniversityDoesNotPartiallySaveUserOrBiography() throws Exception {
        UserPreference pref = createPreference(HEADER + "\nOld note");
        mvc.perform(update().param("bioNote", "New note").param("university", " "))
                .andExpect(status().isBadRequest());
        assertThat(owner.getFullName()).isEqualTo("Original name");
        assertThat(pref.getBioDescription()).isEqualTo(HEADER + "\nOld note");
    }

    @Test void missingPreferencesDoNotCreateFakeCriteriaOrPartiallySaveUser() throws Exception {
        mvc.perform(update().param("bioNote", "New note")).andExpect(status().isBadRequest());
        assertThat(owner.getFullName()).isEqualTo("Original name");
        assertThat(preferences.findByUserId(owner.getId())).isEmpty();
    }

    @Test void profileWithoutPreferencesStillSavesAndKeepsMissingBirthday() throws Exception {
        mvc.perform(update()).andExpect(status().isOk());
        assertThat(owner.getFullName()).isEqualTo("Updated name");
        assertThat(owner.getBirthDate()).isNull();
        assertThat(preferences.findByUserId(owner.getId())).isEmpty();
    }

    @Test void anotherUserCannotUpdateProfileOrBiography() throws Exception {
        User other = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Other user").passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
        mvc.perform(put("/api/v1/profile/user/{id}", other.getId()).header("Authorization", authorization)
                .param("fullName", "Changed").param("phone", "").param("gender", "MALE").param("bioNote", "New note"))
                .andExpect(status().isForbidden());
        assertThat(other.getFullName()).isEqualTo("Other user");
    }

    private MockHttpServletRequestBuilder update() {
        return put("/api/v1/profile/user/{id}", owner.getId()).header("Authorization", authorization)
                .param("fullName", "Updated name").param("phone", "0901234567").param("gender", "MALE");
    }
    private UserPreference createPreference(String bio) {
        return preferences.saveAndFlush(UserPreference.builder().user(owner).targetDistrict("Thu Duc")
                .budgetAmount(3000000.0).budgetMin(2000000.0).budgetMax(4000000.0)
                .targetGender("MALE").topPriority("BUDGET").sleepHabit(2).cleanlinessLevel(4)
                .isSmoking(false).allowPets(true).bioDescription(bio).build());
    }
    private void assertCriteriaUnchanged(UserPreference pref) {
        assertThat(pref.getTargetDistrict()).isEqualTo("Thu Duc");
        assertThat(pref.getBudgetAmount()).isEqualTo(3000000.0);
        assertThat(pref.getBudgetMin()).isEqualTo(2000000.0);
        assertThat(pref.getBudgetMax()).isEqualTo(4000000.0);
        assertThat(pref.getTargetGender()).isEqualTo("MALE");
        assertThat(pref.getTopPriority()).isEqualTo("BUDGET");
        assertThat(pref.getSleepHabit()).isEqualTo(2);
        assertThat(pref.getCleanlinessLevel()).isEqualTo(4);
        assertThat(pref.getIsSmoking()).isFalse();
        assertThat(pref.getAllowPets()).isTrue();
    }
}
