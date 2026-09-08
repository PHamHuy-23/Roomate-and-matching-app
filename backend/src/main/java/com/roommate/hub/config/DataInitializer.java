package com.roommate.hub.config;

import com.roommate.hub.entity.*;
import com.roommate.hub.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final UserPreferenceRepository preferenceRepository;
    private final RoomPostRepository roomPostRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() == 0) {
            String defaultPass = passwordEncoder.encode("123456");

            User u1 = userRepository.save(User.builder()
                    .email("huy@gmail.com")
                    .passwordHash(defaultPass)
                    .fullName("Quang Huy")
                    .gender("MALE")
                    .phone("0901111222")
                    .role(User.Role.ROLE_USER)
                    .build());

            preferenceRepository.save(UserPreference.builder()
                    .user(u1).targetDistrict("Thu Duc").budgetAmount(2000000.0)
                    .sleepHabit(1).cleanlinessLevel(4).isSmoking(false).allowPets(false)
                    .bioDescription("Sinh viên năm 3 IT, chăm chỉ, yên tĩnh.").build());

            User u2 = userRepository.save(User.builder()
                    .email("nam@gmail.com")
                    .passwordHash(defaultPass)
                    .fullName("Văn Nam")
                    .gender("MALE")
                    .phone("0903333444")
                    .role(User.Role.ROLE_USER)
                    .build());

            preferenceRepository.save(UserPreference.builder()
                    .user(u2).targetDistrict("Thu Duc").budgetAmount(2100000.0)
                    .sleepHabit(1).cleanlinessLevel(4).isSmoking(false).allowPets(false)
                    .bioDescription("Hòa đồng, thích học nhóm.").build());

            User u3 = userRepository.save(User.builder()
                    .email("hoang@gmail.com")
                    .passwordHash(defaultPass)
                    .fullName("Minh Hoàng")
                    .gender("MALE")
                    .phone("0905555666")
                    .role(User.Role.ROLE_USER)
                    .build());

            preferenceRepository.save(UserPreference.builder()
                    .user(u3).targetDistrict("Thu Duc").budgetAmount(3500000.0)
                    .sleepHabit(3).cleanlinessLevel(2).isSmoking(true).allowPets(false)
                    .bioDescription("Hay thức khuya chơi game.").build());

            roomPostRepository.save(RoomPost.builder()
                    .author(u2)
                    .title("Tìm 1 bạn nam ở ghép phòng trọ gần ĐH Sư Phạm Kỹ Thuật")
                    .description("Phòng rộng 25m2, có gác lửng, máy lạnh, ban công thoáng mát.")
                    .price(1800000.0)
                    .address("Đường số 6, Linh Trung, TP. Thủ Đức")
                    .maxOccupants(2)
                    .status(RoomPost.PostStatus.AVAILABLE)
                    .build());
        }
    }
}