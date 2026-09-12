-- =============================================================================
-- ROOMMATE HUB - SAMPLE SEED DATA (DML)
-- Database: MySQL 8.0+ / utf8mb4
-- Tất cả tài khoản mẫu có mật khẩu đăng nhập: 123456
-- BCrypt Hash: $2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei
-- =============================================================================

USE `roommate_hub`;

SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------
-- 1. Seed Data: users
-- -------------------------------------------------------------
TRUNCATE TABLE `users`;
INSERT INTO `users` (`id`, `email`, `password_hash`, `full_name`, `gender`, `phone`, `avatar_url`, `role`, `status`, `created_at`) VALUES
(1, 'huy@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Quang Huy', 'MALE', '0970780778', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.720931'),
(2, 'nam@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Văn Nam', 'MALE', '0903333444', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.744246'),
(3, 'hoang@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Minh Hoàng', 'MALE', '0905555666', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.749481'),
(4, 'admin@roommatehub.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Quản Trị Viên', 'MALE', '0909000111', NULL, 'ROLE_ADMIN', 'ACTIVE', '2026-09-06 12:51:21.338691');

-- -------------------------------------------------------------
-- 2. Seed Data: user_preferences
-- -------------------------------------------------------------
TRUNCATE TABLE `user_preferences`;
INSERT INTO `user_preferences` (`id`, `user_id`, `target_district`, `budget_amount`, `sleep_habit`, `cleanliness_level`, `is_smoking`, `allow_pets`, `bio_description`) VALUES
(1, 1, 'Quan 5', 2500000, 3, 4, b'0', b'0', 'Sinh viên năm 3 IT, chăm chỉ, yên tĩnh.'),
(2, 2, 'Thu Duc', 2100000, 1, 4, b'0', b'0', 'Hòa đồng, thích học nhóm.'),
(3, 3, 'Thu Duc', 3500000, 3, 2, b'1', b'0', 'Hay thức khuya chơi game.');

-- -------------------------------------------------------------
-- 3. Seed Data: room_posts
-- -------------------------------------------------------------
TRUNCATE TABLE `room_posts`;
INSERT INTO `room_posts` (`id`, `author_id`, `title`, `description`, `price`, `address`, `max_occupants`, `image_url`, `status`, `created_at`) VALUES
(1, 2, 'Tìm 1 bạn nam ở ghép phòng trọ gần ĐH Sư Phạm Kỹ Thuật', 'Phòng rộng 25m2, có gác lửng, máy lạnh, ban công thoáng mát.', 1800000, 'Đường số 6, Linh Trung, TP. Thủ Đức', 2, NULL, 'AVAILABLE', '2026-09-06 12:45:37.753883'),
(2, 1, 'Tìm 1 bạn nữ ở ghép phòng trọ Thủ Đức', 'Phòng thoáng mát, gần trạm xe buýt, an ninh tốt.', 1500000, 'Khu phố 2, Phường Linh Trung, TP. Thủ Đức', 2, NULL, 'AVAILABLE', '2026-09-06 14:36:54.197589');

-- -------------------------------------------------------------
-- 4. Seed Data: match_requests
-- -------------------------------------------------------------
TRUNCATE TABLE `match_requests`;
INSERT INTO `match_requests` (`id`, `sender_id`, `receiver_id`, `match_score`, `status`, `created_at`) VALUES
(1, 1, 2, 85.2, 'ACCEPTED', '2026-09-06 13:10:37.840143'),
(2, 2, 3, 38.0, 'PENDING', '2026-09-06 13:48:41.172132');

SET FOREIGN_KEY_CHECKS = 1;
