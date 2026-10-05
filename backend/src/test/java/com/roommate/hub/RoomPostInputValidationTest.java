package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.RoomPostService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class RoomPostInputValidationTest {
    @Autowired UserRepository users;
    @Autowired RoomPostRepository posts;
    @Autowired RefreshTokenRepository grants;
    @Autowired JwtUtils jwt;
    @Autowired RoomPostService service;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    MockMvc mvc;
    User owner;
    String authorization;
    RoomPost target;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        owner = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .fullName("Room test owner").passwordHash("test-only-placeholder").gender("MALE")
                .role(User.Role.ROLE_USER).build());
        RefreshToken grant = grants.saveAndFlush(RefreshToken.builder().user(owner)
                .token(UUID.randomUUID().toString()).expiresAt(LocalDateTime.now().plusDays(1)).build());
        authorization = "Bearer " + jwt.generateToken(owner.getEmail(), owner.getId(), grant.getId());
        target = posts.saveAndFlush(RoomPost.builder().author(owner).title("Original title")
                .description("Original description").address("Original address").district("Original district")
                .price(2000000.0).deposit(1000000.0).electricityWaterCost(300000.0).area(30.0)
                .maxOccupants(3).currentOccupants(1).amenities("Wi-Fi")
                .status(RoomPost.PostStatus.APPROVED).build());
    }
    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void legacyPostWithoutAreaCanBeUpdatedWithActualFractionalArea() throws Exception {
        target.setArea(null);
        target.setAmenities("Chỗ để xe,Wi-Fi");
        posts.saveAndFlush(target);
        mvc.perform(put("/api/v1/posts/{id}", target.getId()).header("Authorization", authorization)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Updated legacy post\",\"area\":25.5}"))
                .andExpect(status().isOk()).andExpect(jsonPath("area").value(25.5))
                .andExpect(jsonPath("status").value("PENDING"));
        assertThat(target.getArea()).isEqualTo(25.5);
        assertThat(target.getTitle()).isEqualTo("Updated legacy post");
        assertThat(target.getAmenities()).isEqualTo("Chỗ để xe,Wi-Fi");
        assertThat(target.getPrice()).isEqualTo(2000000.0);
        assertThat(target.getCurrentOccupants()).isEqualTo(1);
        assertThat(target.getDeposit()).isEqualTo(1000000.0);
    }

    @Test void partialEditRejectsBlankAndOversizedTextWithoutChangingThePost() throws Exception {
        for (String field : new String[]{"title", "description", "address", "district"}) {
            for (String value : new String[]{"", "   "}) {
                update("{\"" + field + "\":\"" + value + "\",\"price\":2500000}", 400);
                assertUnchanged();
            }
        }
        String[] fields = {"title", "address", "district", "amenities"};
        int[] lengths = {201, 256, 101, 501};
        for (int i = 0; i < fields.length; i++) {
            update("{\"" + fields[i] + "\":\"" + "x".repeat(lengths[i]) + "\"}", 400);
            assertUnchanged();
        }
    }

    @Test void partialEditRejectsInvalidCostsAndAreaBeforeChangingContentOrStatus() throws Exception {
        for (String field : new String[]{"price", "deposit", "electricityWaterCost", "area"}) {
            update("{\"title\":\"Changed title\",\"" + field + "\":-1}", 400);
            assertUnchanged();
        }
        for (int price : new int[]{0, 1, 99999}) {
            update("{\"price\":" + price + "}", 400);
            assertUnchanged();
        }
    }

    @Test void partialEditKeepsOmittedAndNullFieldsAndAcceptsBoundaryValues() throws Exception {
        update("{\"title\":\"New title\",\"address\":null}", 200);
        assertThat(target.getTitle()).isEqualTo("New title");
        assertThat(target.getAddress()).isEqualTo("Original address");
        assertThat(target.getPrice()).isEqualTo(2000000.0);
        assertThat(target.getAmenities()).isEqualTo("Wi-Fi");
        assertThat(target.getCurrentOccupants()).isEqualTo(1);
        assertThat(target.getStatus()).isEqualTo(RoomPost.PostStatus.PENDING);
        update("{\"title\":\"" + "x".repeat(200) + "\",\"price\":100000,"
                + "\"deposit\":0,\"electricityWaterCost\":0,\"area\":0,\"amenities\":\"\"}", 200);
        assertThat(target.getPrice()).isEqualTo(100000.0);
        assertThat(target.getDeposit()).isZero();
        assertThat(target.getElectricityWaterCost()).isZero();
        assertThat(target.getArea()).isZero();
        assertThat(target.getAmenities()).isEmpty();
    }

    @Test void createStillRequiresMandatoryFieldsAndAcceptsOptionalOmissions() throws Exception {
        long before = posts.count();
        for (String body : new String[]{"{}", "{\"title\":\"Test\"}",
                validCreate().replace("\"price\":100000,", ""),
                validCreate().replace("\"title\":\"Test\"", "\"title\":\"   \""),
                validCreate().replace("\"title\":\"Test\"", "\"title\":\"" + "x".repeat(201) + "\"")}) {
            mvc.perform(post("/api/v1/posts").header("Authorization", authorization)
                    .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isBadRequest());
            assertThat(posts.count()).isEqualTo(before);
        }
        mvc.perform(post("/api/v1/posts").header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(validCreate())).andExpect(status().isOk());
        assertThat(posts.count()).isEqualTo(before + 1);
    }

    @Test void nonFiniteNumbersCannotBePersistedByCreateOrUpdate() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(owner.getEmail(), null, List.of()));
        long before = posts.count();
        for (double invalid : new double[]{Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY}) {
            for (String field : new String[]{"price", "deposit", "electricityWaterCost", "area"}) {
                CreateRoomPostDTO dto = new CreateRoomPostDTO();
                switch (field) {
                    case "price" -> dto.setPrice(invalid);
                    case "deposit" -> dto.setDeposit(invalid);
                    case "electricityWaterCost" -> dto.setElectricityWaterCost(invalid);
                    case "area" -> dto.setArea(invalid);
                }
                assertThatThrownBy(() -> service.createPost(dto)).isInstanceOf(IllegalArgumentException.class);
                assertThatThrownBy(() -> service.updatePost(target.getId(), dto)).isInstanceOf(IllegalArgumentException.class);
                assertUnchanged();
                assertThat(posts.count()).isEqualTo(before);
            }
        }
    }

    private void update(String body, int expected) throws Exception {
        mvc.perform(put("/api/v1/posts/{id}", target.getId()).header("Authorization", authorization)
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().is(expected));
    }
    private void assertUnchanged() {
        var saved = posts.findById(target.getId()).orElseThrow();
        assertThat(saved.getTitle()).isEqualTo("Original title");
        assertThat(saved.getAddress()).isEqualTo("Original address");
        assertThat(saved.getDescription()).isEqualTo("Original description");
        assertThat(saved.getDistrict()).isEqualTo("Original district");
        assertThat(saved.getAmenities()).isEqualTo("Wi-Fi");
        assertThat(saved.getPrice()).isEqualTo(2000000.0);
        assertThat(saved.getDeposit()).isEqualTo(1000000.0);
        assertThat(saved.getElectricityWaterCost()).isEqualTo(300000.0);
        assertThat(saved.getArea()).isEqualTo(30.0);
        assertThat(saved.getStatus()).isEqualTo(RoomPost.PostStatus.APPROVED);
    }
    private String validCreate() {
        return "{\"title\":\"Test\",\"description\":\"Test description\",\"address\":\"Test address\","
                + "\"price\":100000,\"maxOccupants\":2}";
    }
}
