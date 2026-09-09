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

SET FOREIGN_KEY_CHECKS = 1;
