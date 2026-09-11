-- =============================================================================
-- ROOMMATE HUB - FULL DATABASE SETUP SCRIPT (SCHEMA + SEED DATA)
-- Database: MySQL 8.0+ / utf8mb4
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `roommate_hub`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `roommate_hub`;

SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------
-- 1. Table: users
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `email` VARCHAR(100) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `gender` VARCHAR(10) NOT NULL,
    `phone` VARCHAR(20) DEFAULT NULL,
    `avatar_url` VARCHAR(255) DEFAULT NULL,
    `role` ENUM('ROLE_ADMIN', 'ROLE_USER') NOT NULL DEFAULT 'ROLE_USER',
    `status` VARCHAR(255) NOT NULL DEFAULT 'ACTIVE',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 2. Table: user_preferences
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `user_preferences`;
CREATE TABLE `user_preferences` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `target_district` VARCHAR(100) NOT NULL,
    `budget_amount` DOUBLE NOT NULL,
    `sleep_habit` INT NOT NULL COMMENT '1: Ngủ sớm, 2: Bình thường, 3: Cú đêm',
    `cleanliness_level` INT NOT NULL COMMENT 'Thang điểm từ 1 đến 5',
    `is_smoking` BIT(1) NOT NULL DEFAULT b'0',
    `allow_pets` BIT(1) NOT NULL DEFAULT b'0',
    `bio_description` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK_user_preferences_user` (`user_id`),
    CONSTRAINT `FK_user_preferences_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 3. Table: room_posts
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `room_posts`;
CREATE TABLE `room_posts` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `author_id` BIGINT NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NOT NULL,
    `price` DOUBLE NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `max_occupants` INT NOT NULL DEFAULT 2,
    `image_url` VARCHAR(255) DEFAULT NULL,
    `status` ENUM('AVAILABLE', 'PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'AVAILABLE',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    KEY `FK_room_posts_author` (`author_id`),
    CONSTRAINT `FK_room_posts_author` FOREIGN KEY (`author_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 4. Table: match_requests
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `match_requests`;
CREATE TABLE `match_requests` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `sender_id` BIGINT NOT NULL,
    `receiver_id` BIGINT NOT NULL,
    `match_score` DOUBLE NOT NULL,
    `status` ENUM('PENDING', 'ACCEPTED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK_match_request_pair` (`sender_id`, `receiver_id`),
    KEY `FK_match_requests_receiver` (`receiver_id`),
    CONSTRAINT `FK_match_requests_sender` FOREIGN KEY (`sender_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_match_requests_receiver` FOREIGN KEY (`receiver_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================
-- SEED DATA (MẬT KHẨU ĐĂNG NHẬP: 123456)
-- =============================================================

INSERT INTO `users` (`id`, `email`, `password_hash`, `full_name`, `gender`, `phone`, `avatar_url`, `role`, `status`, `created_at`) VALUES
(1, 'huy@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Quang Huy', 'MALE', '0970780778', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.720931'),
(2, 'nam@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Văn Nam', 'MALE', '0903333444', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.744246'),
(3, 'hoang@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Minh Hoàng', 'MALE', '0905555666', NULL, 'ROLE_USER', 'ACTIVE', '2026-09-06 12:45:37.749481'),
(4, 'admin@roommatehub.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei', 'Quản Trị Viên', 'MALE', '0909000111', NULL, 'ROLE_ADMIN', 'ACTIVE', '2026-09-06 12:51:21.338691')
ON DUPLICATE KEY UPDATE id=id;

INSERT INTO `user_preferences` (`id`, `user_id`, `target_district`, `budget_amount`, `sleep_habit`, `cleanliness_level`, `is_smoking`, `allow_pets`, `bio_description`) VALUES
(1, 1, 'Quan 5', 2500000, 3, 4, b'0', b'0', 'Sinh viên năm 3 IT, chăm chỉ, yên tĩnh.'),
(2, 2, 'Thu Duc', 2100000, 1, 4, b'0', b'0', 'Hòa đồng, thích học nhóm.'),
(3, 3, 'Thu Duc', 3500000, 3, 2, b'1', b'0', 'Hay thức khuya chơi game.')
ON DUPLICATE KEY UPDATE user_id=user_id;

INSERT INTO `room_posts` (`id`, `author_id`, `title`, `description`, `price`, `address`, `max_occupants`, `image_url`, `status`, `created_at`) VALUES
(1, 2, 'Tìm 1 bạn nam ở ghép phòng trọ gần ĐH Sư Phạm Kỹ Thuật', 'Phòng rộng 25m2, có gác lửng, máy lạnh, ban công thoáng mát.', 1800000, 'Đường số 6, Linh Trung, TP. Thủ Đức', 2, NULL, 'AVAILABLE', '2026-09-06 12:45:37.753883'),
(2, 1, 'Tìm 1 bạn nữ ở ghép phòng trọ Thủ Đức', 'Phòng thoáng mát, gần trạm xe buýt, an ninh tốt.', 1500000, 'Khu phố 2, Phường Linh Trung, TP. Thủ Đức', 2, NULL, 'AVAILABLE', '2026-09-06 14:36:54.197589')
ON DUPLICATE KEY UPDATE id=id;

INSERT INTO `match_requests` (`id`, `sender_id`, `receiver_id`, `match_score`, `status`, `created_at`) VALUES
(1, 1, 2, 85.2, 'ACCEPTED', '2026-09-06 13:10:37.840143'),
(2, 2, 3, 38.0, 'PENDING', '2026-09-06 13:48:41.172132')
ON DUPLICATE KEY UPDATE id=id;

-- -------------------------------------------------------------
-- 5. Table: viewing_appointments
-- Quản lý Lịch hẹn xem phòng trực tiếp
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `viewing_appointments`;
CREATE TABLE `viewing_appointments` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `requester_id` BIGINT NOT NULL,
    `host_id` BIGINT NOT NULL,
    `room_post_id` BIGINT NOT NULL,
    `appointment_time` DATETIME NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, COMPLETED, CANCELLED
    `note` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `FK_viewing_appointments_requester` FOREIGN KEY (`requester_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_viewing_appointments_host` FOREIGN KEY (`host_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_viewing_appointments_room_post` FOREIGN KEY (`room_post_id`) 
        REFERENCES `room_posts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 6. Table: contact_permissions
-- Cơ chế Double Opt-in bảo vệ quyền riêng tư (chỉ cho xem SĐT khi 2 bên đồng ý)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `contact_permissions`;
CREATE TABLE `contact_permissions` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL,          -- Người cho phép xem
    `granted_to_id` BIGINT NOT NULL,    -- Người được phép xem SĐT
    `match_request_id` BIGINT NOT NULL,
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_contact_permissions_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_contact_permissions_granted_to` FOREIGN KEY (`granted_to_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_contact_permissions_match_request` FOREIGN KEY (`match_request_id`) 
        REFERENCES `match_requests` (`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_contact_grant` (`user_id`, `granted_to_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 7. Table: reports
-- Quản lý Báo cáo Tố cáo vi phạm
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `reporter_id` BIGINT NOT NULL,
    `target_id` BIGINT NOT NULL,
    `target_type` VARCHAR(20) NOT NULL, -- 'USER' hoặc 'ROOM_POST'
    `reason` TEXT NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, RESOLVED, DISMISSED
    `action_note` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_reports_reporter` FOREIGN KEY (`reporter_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- 8. Indexes (Chỉ mục) giúp tăng tốc độ tìm kiếm
-- -------------------------------------------------------------
-- Giả sử bảng room_posts có các cột district và price (trong schema cũ có address và price)
-- Nếu bảng chưa có cột district thì bạn có thể lập index trên cột address thay thế.
CREATE INDEX `idx_room_posts_price` ON `room_posts`(`price`);
-- Lưu ý: Index cho address có thể cần chỉ định độ dài nếu dùng VARCHAR dài
-- CREATE INDEX `idx_room_posts_address` ON `room_posts`(`address`(100));


SET FOREIGN_KEY_CHECKS = 1;
