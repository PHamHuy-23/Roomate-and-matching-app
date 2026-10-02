package com.roommate.hub;

import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import com.roommate.hub.service.*;
import com.roommate.hub.util.DistrictNames;
import com.roommate.hub.config.JwtUtils;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class DistrictCompatibilityTest {
    @Autowired UserRepository users;
    @Autowired UserPreferenceRepository preferences;
    @Autowired BlockedUserRepository blocks;
    @Autowired RoomPostRepository posts;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired MatchingService matching;
    @Autowired ProfileService profiles;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;

    @Test void aliasesShareAKeyWithoutChangingUnknownDistricts() {
        for (String value : List.of("Thu Duc", "THỦ ĐỨC", " TP. Thủ Đức ",
                "Thành phố Thủ Đức", "Thủ Đức, TP.HCM", "Thu  Duc, Ho Chi Minh", "Thu\u0309 Đu\u031b\u0301c")) {
            assertThat(DistrictNames.canonical(value)).isEqualTo("Thu Duc");
            assertThat(DistrictNames.same(value, "Thu Duc")).isTrue();
        }
        assertThat(DistrictNames.canonical("Quận Bình Thạnh, TP. Hồ Chí Minh")).isEqualTo("Binh Thanh");
        assertThat(DistrictNames.canonical("Huyện Hóc Môn")).isEqualTo("Hoc Mon");
        assertThat(DistrictNames.canonical("Q.1")).isEqualTo("Quan 1");
        assertThat(DistrictNames.canonical("Quan10")).isEqualTo("Quan 10");
        assertThat(DistrictNames.same("Quận 1", "Quận 10")).isFalse();
        assertThat(DistrictNames.same("Bình Tân", "Bình Thạnh")).isFalse();
        assertThat(DistrictNames.same(null, "")).isFalse();
        assertThat(DistrictNames.canonical("  Khu vực  mới  ")).isEqualTo("Khu vực mới");
        assertThat(DistrictNames.same("Khu vực mới", "Binh Thanh")).isFalse();
    }

    @Test void databaseMatchingRecognizesLegacyRowsAndPreservesEligibilityRules() {
        User me = user("MALE");
        var mine = preference(me, "Thu Duc");
        mine.setTargetGender("MALE"); preferences.flush();
        User same = user("MALE");
        var legacy = preference(same, " TP. Thủ Đức, TP.HCM ");
        User wrongDistrict = user("MALE"); preference(wrongDistrict, "Bình Thạnh");
        User wrongGender = user("FEMALE"); preference(wrongGender, "Thủ Đức");
        User locked = user("MALE"); locked.setStatus("LOCKED"); preference(locked, "Thủ Đức");
        User inactive = user("MALE"); inactive.setSearchActive(false); preference(inactive, "Thủ Đức");
        User blocked = user("MALE"); preference(blocked, "Thủ Đức");
        blocks.saveAndFlush(BlockedUser.builder().user(blocked).blockedUser(me).build());
        User rejectsMale = user("MALE"); var reciprocal = preference(rejectsMale, "Thu Duc");
        reciprocal.setTargetGender("FEMALE"); preferences.flush();
        for (String alias : List.of("Thu Duc", "Thủ Đức", "Thành phố Thủ Đức")) {
            mine.setTargetDistrict(alias); preferences.flush();
            var result = matching.getRecommendations(me);
            assertThat(result).extracting(item -> item.getUserId()).containsExactly(same.getId());
            assertThat(result.getFirst().getTargetDistrict()).isEqualTo("Thu Duc");
        }
        assertThat(legacy.getTargetDistrict()).isEqualTo(" TP. Thủ Đức, TP.HCM ");
        assertThat(profiles.getPreferences(same.getId()).getTargetDistrict()).isEqualTo("Thu Duc");
        assertThat(profiles.getPublicProfile(same.getId()).getTargetDistrict()).isEqualTo("Thu Duc");
        // Unknown old names still match themselves, never the default district.
        mine.setTargetDistrict("Khu vực mới"); legacy.setTargetDistrict("Khu vực mới");
        preferences.flush();
        assertThat(matching.getRecommendations(me)).extracting(item -> item.getUserId()).containsExactly(same.getId());
    }

    @Test void apiWritesCanonicalPreferencesAndRoomDistrictsWhileReadingLegacyDataSafely() throws Exception {
        User owner = user("MALE");
        preference(owner, "Thủ Đức");
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(owner).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
        String auth = "Bearer " + jwt.generateToken(owner.getEmail(), owner.getId(), grant.getId());
        var mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        mvc.perform(put("/api/v1/profile/preferences/{id}", owner.getId()).header("Authorization", auth)
                .contentType(MediaType.APPLICATION_JSON).content("{\"targetDistrict\":\"Quận Bình Thạnh, TP.HCM\","
                        + "\"budgetAmount\":2000000,\"sleepHabit\":1,\"cleanlinessLevel\":4,\"isSmoking\":false,\"allowPets\":false}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.targetDistrict").value("Binh Thanh"));
        assertThat(preferences.findByUserId(owner.getId()).orElseThrow().getTargetDistrict()).isEqualTo("Binh Thanh");
        mvc.perform(post("/api/v1/posts").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Test room\",\"description\":\"Test description\",\"address\":\"Test address\","
                        + "\"district\":\"Thủ Đức, TP.HCM\",\"price\":2000000,\"maxOccupants\":2}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.district").value("Thu Duc"));
        var room = posts.findAll().stream().filter(p -> p.getAuthor().getId().equals(owner.getId())).findFirst().orElseThrow();
        assertThat(room.getDistrict()).isEqualTo("Thu Duc");
        room.setDistrict("Thủ Đức"); posts.flush();
        mvc.perform(get("/api/v1/posts/my").header("Authorization", auth))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].district").value("Thu Duc"));
        assertThat(room.getDistrict()).isEqualTo("Thủ Đức");
        mvc.perform(put("/api/v1/posts/{id}", room.getId()).header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"district\":\"Quận 3, TP.HCM\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.district").value("Quan 3"));
        mvc.perform(put("/api/v1/posts/{id}", room.getId()).header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"district\":\"Khu vực mới\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.district").value("Khu vực mới"));
    }

    private User user(String gender) {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid").fullName("District test")
                .passwordHash("test-only-placeholder").gender(gender).role(User.Role.ROLE_USER).build());
    }
    private UserPreference preference(User user, String district) {
        return preferences.saveAndFlush(UserPreference.builder().user(user).targetDistrict(district).targetGender("ANY")
                .budgetAmount(2000000.0).sleepHabit(1).cleanlinessLevel(4).isSmoking(false).allowPets(false).build());
    }
}
