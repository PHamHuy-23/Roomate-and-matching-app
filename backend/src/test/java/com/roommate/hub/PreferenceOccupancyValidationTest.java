package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.service.ProfileService;
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
import java.time.LocalDateTime;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class PreferenceOccupancyValidationTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired RoomPostRepository posts;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired ProfileService profile;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    MockMvc mvc;
    User owner;
    String authorization;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        owner = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Test owner").passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(owner)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        authorization = "Bearer " + jwt.generateToken(owner.getEmail(), owner.getId(), grant.getId());
    }
    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void sleepOutsideOneToThreeIsRejectedWithoutInsertingPreferences() throws Exception {
        for (int value : new int[]{-1, 0, 4, 100}) {
            putPreferences(pref(value, 4), 400);
            assertThat(preferences.findByUserId(owner.getId())).isEmpty();
        }
    }
    @Test void cleanlinessOutsideOneToFiveCannotOverwriteExistingPreferences() throws Exception {
        putPreferences(pref(2, 4), 200);
        for (int value : new int[]{-1, 0, 6, 100}) {
            putPreferences(pref(1, value), 400);
            var saved = preferences.findByUserId(owner.getId()).orElseThrow();
            assertThat(saved.getCleanlinessLevel()).isEqualTo(4);
            assertThat(saved.getSleepHabit()).isEqualTo(2);
        }
    }
    @Test void validPreferenceBoundariesAndLegacyNoRangeAreAccepted() throws Exception {
        putPreferences(pref(1, 1), 200);
        putPreferences(pref(3, 5).replace("\"budgetMin\":1000000,\"budgetMax\":4000000,", ""), 200);
        var saved = preferences.findByUserId(owner.getId()).orElseThrow();
        assertThat(saved.getSleepHabit()).isEqualTo(3);
        assertThat(saved.getCleanlinessLevel()).isEqualTo(5);
        assertThat(saved.getBudgetMin()).isNull();
    }
    @Test void malformedBudgetRangesAndOversizedDistrictAreBadRequests() throws Exception {
        String valid = pref(1, 4);
        for (String invalid : new String[]{
                valid.replace("\"budgetMax\":4000000,", ""),
                valid.replace("\"budgetMin\":1000000,", ""),
                valid.replace("\"budgetMin\":1000000", "\"budgetMin\":5000000"),
                valid.replace("\"budgetMin\":1000000", "\"budgetMin\":-1"),
                valid.replace("\"budgetAmount\":3000000", "\"budgetAmount\":499999"),
                valid.replace("TEST_DISTRICT", "x".repeat(101))}) {
            putPreferences(invalid, 400);
            assertThat(preferences.findByUserId(owner.getId())).isEmpty();
        }
        putPreferences(valid.replace("\"budgetMin\":1000000", "\"budgetMin\":0")
                .replace("\"budgetMax\":4000000", "\"budgetMax\":500000"), 200);
    }
    @Test void nonFiniteBudgetsAreRejectedBeforePersistence() {
        for (double invalid : new double[]{Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY}) {
            var dto = UserPreferenceDTO.builder().budgetAmount(invalid).build();
            assertThatThrownBy(() -> profile.saveOrUpdatePreferences(owner.getId(), dto))
                    .isInstanceOf(IllegalArgumentException.class);
            dto.setBudgetAmount(3000000.0); dto.setBudgetMin(0.0); dto.setBudgetMax(invalid);
            assertThatThrownBy(() -> profile.saveOrUpdatePreferences(owner.getId(), dto))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThat(preferences.findByUserId(owner.getId())).isEmpty();
        }
    }
    @Test void creationCannotExceedCapacityAndMissingCurrentOccupantsDefaultsToZero() throws Exception {
        long before = posts.count();
        mvc.perform(post("/api/v1/posts").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(room(2, 3)))
                .andExpect(status().isBadRequest());
        assertThat(posts.count()).isEqualTo(before);
        mvc.perform(post("/api/v1/posts").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(room(2, 0).replace(",\"currentOccupants\":0", "")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.currentOccupants").value(0));
        mvc.perform(post("/api/v1/posts").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(room(2, 2)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.currentOccupants").value(2));
    }
    @Test void partialCapacityReductionUsesStoredOccupantsAndLeavesStatusUnchangedOnFailure() throws Exception {
        var target = roomEntity();
        update(target, "{\"maxOccupants\":1}", 400);
        assertThat(target.getMaxOccupants()).isEqualTo(3);
        assertThat(target.getCurrentOccupants()).isEqualTo(2);
        assertThat(target.getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
        update(target, "{\"maxOccupants\":2}", 200);
        assertThat(target.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
        assertThat(target.getCurrentOccupants()).isEqualTo(2);
    }
    @Test void invalidPartialOccupantsCannotBeSavedButBothFieldsCanBeUpdatedTogether() throws Exception {
        var target = roomEntity();
        for (String invalid : new String[]{"{\"maxOccupants\":0}", "{\"maxOccupants\":-1}",
                "{\"currentOccupants\":-1}", "{\"currentOccupants\":4}"}) {
            update(target, invalid, 400);
            assertThat(target.getMaxOccupants()).isEqualTo(3);
            assertThat(target.getCurrentOccupants()).isEqualTo(2);
            assertThat(target.getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
        }
        update(target, "{\"maxOccupants\":1,\"currentOccupants\":1}", 200);
        assertThat(target.getMaxOccupants()).isEqualTo(1);
        assertThat(target.getCurrentOccupants()).isEqualTo(1);
    }
    @Test void unrelatedPartialEditPreservesOccupantsAndOwnershipChecks() throws Exception {
        var target = roomEntity();
        update(target, "{\"title\":\"Updated title\"}", 200);
        assertThat(target.getMaxOccupants()).isEqualTo(3);
        assertThat(target.getCurrentOccupants()).isEqualTo(2);
        User other = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Other").passwordHash("test-only-placeholder").gender("MALE").role(User.Role.ROLE_USER).build());
        var otherRoom = roomEntity(); otherRoom.setAuthor(other); posts.saveAndFlush(otherRoom);
        update(otherRoom, "{\"maxOccupants\":1}", 403);
    }
    private void putPreferences(String body, int expectedStatus) throws Exception {
        mvc.perform(put("/api/v1/profile/preferences/{id}", owner.getId()).header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().is(expectedStatus));
    }
    private void update(RoomPost target, String body, int expectedStatus) throws Exception {
        mvc.perform(put("/api/v1/posts/{id}", target.getId()).header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().is(expectedStatus));
    }
    private String pref(int sleep, int clean) {
        return "{\"targetDistrict\":\"TEST_DISTRICT\",\"budgetAmount\":3000000,"
                + "\"budgetMin\":1000000,\"budgetMax\":4000000,\"sleepHabit\":" + sleep
                + ",\"cleanlinessLevel\":" + clean + ",\"isSmoking\":false,\"allowPets\":false}";
    }
    private String room(int max, int current) {
        return "{\"title\":\"Test room\",\"description\":\"Test description\",\"address\":\"Test address\","
                + "\"price\":2000000,\"maxOccupants\":" + max + ",\"currentOccupants\":" + current + "}";
    }
    private RoomPost roomEntity() {
        return posts.saveAndFlush(RoomPost.builder().author(owner).title("Test room").description("Test description")
                .address("Test address").price(2000000.0).maxOccupants(3).currentOccupants(2)
                .status(RoomPost.PostStatus.APPROVED).build());
    }
}
