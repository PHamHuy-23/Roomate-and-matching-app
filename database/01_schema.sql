-- =============================================================================
-- ROOMMATE HUB - DATABASE SCHEMA (DDL)
-- Database: MySQL 8.0+ / utf8mb4
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `roommate_hub`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `roommate_hub`;

SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------
-- 1. Table: users
-- Lưu trữ thông tin tài khoản người dùng & quản trị viên
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
-- Lưu trữ tiêu chí, thói quen sinh hoạt phục vụ thuật toán ghép đôi
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
-- Lưu trữ bài đăng tìm bạn ở ghép phòng trọ / căn hộ
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
-- Quản lý yêu cầu kết nối / ghép đôi phòng (Double Opt-in)
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
