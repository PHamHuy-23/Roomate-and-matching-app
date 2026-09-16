-- =============================================================================
-- ROOMMATE HUB - DU LIEU MAU CHO DISCOVERY FEED / COMPATIBILITY
-- MySQL 8.0+
--
-- Tai khoan dung de test:
--   Email:    huy@gmail.com
--   Mat khau: 123456 (neu dang dung bo seed mac dinh cua du an)
--
-- Script khong TRUNCATE bang va co the chay lai ma khong tao user trung.
-- Cac ung vien duoc tao cung gioi tinh va cung quan voi tai khoan test,
-- de dap ung bo loc cung hien tai cua MatchingService.
-- =============================================================================

USE `roommate_hub`;

-- Dong bo charset/collation cua bien va chuoi literal voi schema hien tai.
-- Neu khong co dong nay, MySQL 8 co the bao Error 1267 khi so sanh
-- utf8mb4_0900_ai_ci cua session voi utf8mb4_unicode_ci cua cot email.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET @test_email = _utf8mb4'huy@gmail.com' COLLATE utf8mb4_unicode_ci;
SET @test_user_id = (SELECT `id` FROM `users` WHERE `email` = @test_email LIMIT 1);
SET @test_password = (SELECT `password_hash` FROM `users` WHERE `id` = @test_user_id);
SET @test_gender = (SELECT `gender` FROM `users` WHERE `id` = @test_user_id);
SET @test_district = (
    SELECT `target_district`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);
SET @test_budget = (
    SELECT `budget_amount`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);
SET @test_sleep = (
    SELECT `sleep_habit`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);
SET @test_cleanliness = (
    SELECT `cleanliness_level`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);
SET @test_smoking = (
    SELECT `is_smoking`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);
SET @test_pets = (
    SELECT `allow_pets`
    FROM `user_preferences`
    WHERE `user_id` = @test_user_id
    LIMIT 1
);

START TRANSACTION;

-- Ba ung vien phu ba nhom diem: cao, trung binh va thap.
INSERT IGNORE INTO `users`
    (`email`, `password_hash`, `full_name`, `gender`, `phone`, `avatar_url`, `role`, `status`)
SELECT
    'demo.match.high@roommatehub.local', @test_password, 'Tuấn Minh',
    @test_gender, '0908000101', NULL, 'ROLE_USER', 'ACTIVE'
WHERE @test_user_id IS NOT NULL;

INSERT IGNORE INTO `users`
    (`email`, `password_hash`, `full_name`, `gender`, `phone`, `avatar_url`, `role`, `status`)
SELECT
    'demo.match.medium@roommatehub.local', @test_password, 'Hoàng Nam',
    @test_gender, '0908000102', NULL, 'ROLE_USER', 'ACTIVE'
WHERE @test_user_id IS NOT NULL;

INSERT IGNORE INTO `users`
    (`email`, `password_hash`, `full_name`, `gender`, `phone`, `avatar_url`, `role`, `status`)
SELECT
    'demo.match.low@roommatehub.local', @test_password, 'Gia Bảo',
    @test_gender, '0908000103', NULL, 'ROLE_USER', 'ACTIVE'
WHERE @test_user_id IS NOT NULL;

-- Gan nhu trung khop hoan toan: badge xanh, diem thuong tren 90%.
INSERT INTO `user_preferences`
    (`user_id`, `target_district`, `budget_amount`, `sleep_habit`,
     `cleanliness_level`, `is_smoking`, `allow_pets`, `bio_description`)
SELECT
    u.`id`, @test_district, ROUND(@test_budget * 1.05), @test_sleep,
    @test_cleanliness, @test_smoking, @test_pets,
    'Dữ liệu mẫu: giờ giấc, ngân sách và nếp sống rất tương đồng.'
FROM `users` u
WHERE u.`email` = 'demo.match.high@roommatehub.local'
ON DUPLICATE KEY UPDATE
    `target_district` = @test_district,
    `budget_amount` = ROUND(@test_budget * 1.05),
    `sleep_habit` = @test_sleep,
    `cleanliness_level` = @test_cleanliness,
    `is_smoking` = @test_smoking,
    `allow_pets` = @test_pets,
    `bio_description` = 'Dữ liệu mẫu: giờ giấc, ngân sách và nếp sống rất tương đồng.';

-- Co mot vai khac biet: badge cam, diem du kien khoang 65-75%.
INSERT INTO `user_preferences`
    (`user_id`, `target_district`, `budget_amount`, `sleep_habit`,
     `cleanliness_level`, `is_smoking`, `allow_pets`, `bio_description`)
SELECT
    u.`id`, @test_district, ROUND(@test_budget * 1.5),
    CASE WHEN @test_sleep = 1 THEN 2 WHEN @test_sleep = 2 THEN 1 ELSE 2 END,
    CASE WHEN @test_cleanliness >= 3 THEN @test_cleanliness - 2 ELSE @test_cleanliness + 2 END,
    @test_smoking, @test_pets,
    'Dữ liệu mẫu: có vài khác biệt để kiểm tra phần điểm cần lưu ý.'
FROM `users` u
WHERE u.`email` = 'demo.match.medium@roommatehub.local'
ON DUPLICATE KEY UPDATE
    `target_district` = @test_district,
    `budget_amount` = ROUND(@test_budget * 1.5),
    `sleep_habit` = CASE WHEN @test_sleep = 1 THEN 2 WHEN @test_sleep = 2 THEN 1 ELSE 2 END,
    `cleanliness_level` = CASE
        WHEN @test_cleanliness >= 3 THEN @test_cleanliness - 2
        ELSE @test_cleanliness + 2
    END,
    `is_smoking` = @test_smoking,
    `allow_pets` = @test_pets,
    `bio_description` = 'Dữ liệu mẫu: có vài khác biệt để kiểm tra phần điểm cần lưu ý.';

-- Khac biet lon: badge xam, diem du kien duoi 60%.
INSERT INTO `user_preferences`
    (`user_id`, `target_district`, `budget_amount`, `sleep_habit`,
     `cleanliness_level`, `is_smoking`, `allow_pets`, `bio_description`)
SELECT
    u.`id`, @test_district, ROUND(@test_budget * 2),
    CASE WHEN @test_sleep = 1 THEN 3 ELSE 1 END,
    CASE WHEN @test_cleanliness >= 3 THEN 1 ELSE 5 END,
    NOT @test_smoking, NOT @test_pets,
    'Dữ liệu mẫu: khác biệt lớn về giờ giấc và thói quen sinh hoạt.'
FROM `users` u
WHERE u.`email` = 'demo.match.low@roommatehub.local'
ON DUPLICATE KEY UPDATE
    `target_district` = @test_district,
    `budget_amount` = ROUND(@test_budget * 2),
    `sleep_habit` = CASE WHEN @test_sleep = 1 THEN 3 ELSE 1 END,
    `cleanliness_level` = CASE WHEN @test_cleanliness >= 3 THEN 1 ELSE 5 END,
    `is_smoking` = NOT @test_smoking,
    `allow_pets` = NOT @test_pets,
    `bio_description` = 'Dữ liệu mẫu: khác biệt lớn về giờ giấc và thói quen sinh hoạt.';

COMMIT;

-- Xem nhanh cac ban ghi vua tao.
SELECT
    u.`id`, u.`full_name`, u.`email`, p.`target_district`,
    p.`budget_amount`, p.`sleep_habit`, p.`cleanliness_level`,
    p.`is_smoking`, p.`allow_pets`
FROM `users` u
JOIN `user_preferences` p ON p.`user_id` = u.`id`
WHERE u.`email` LIKE 'demo.match.%@roommatehub.local'
ORDER BY u.`email`;

-- Neu can xoa du lieu mau, chay lenh sau (FK se xoa preference kem theo):
-- DELETE FROM `users` WHERE `email` LIKE 'demo.match.%@roommatehub.local';
