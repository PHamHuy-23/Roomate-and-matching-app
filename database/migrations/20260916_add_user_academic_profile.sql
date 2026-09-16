-- =============================================================================
-- ROOMMATE HUB - MIGRATION: NGAY SINH VA TRUONG DAI HOC
-- Chay file nay mot lan cho database da duoc tao truoc thay doi QH2-4.2.
-- Database khoi tao moi bang 01_schema.sql hoac roommate_hub.sql khong can chay.
-- =============================================================================

USE `roommate_hub`;

-- MySQL khong ho tro ADD COLUMN IF NOT EXISTS tren moi phien ban.
-- Kiem tra metadata truoc de script co the chay lai an toan.
SET @has_birth_date = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
      AND COLUMN_NAME = 'birth_date'
);
SET @birth_date_sql = IF(
    @has_birth_date = 0,
    'ALTER TABLE `users` ADD COLUMN `birth_date` DATE DEFAULT NULL AFTER `avatar_url`',
    'SELECT 1'
);
PREPARE birth_date_statement FROM @birth_date_sql;
EXECUTE birth_date_statement;
DEALLOCATE PREPARE birth_date_statement;

SET @has_university = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
      AND COLUMN_NAME = 'university'
);
SET @university_sql = IF(
    @has_university = 0,
    'ALTER TABLE `users` ADD COLUMN `university` VARCHAR(150) DEFAULT NULL AFTER `birth_date`',
    'SELECT 1'
);
PREPARE university_statement FROM @university_sql;
EXECUTE university_statement;
DEALLOCATE PREPARE university_statement;

-- Du lieu mau cho cac tai khoan co san.
UPDATE `users`
SET `birth_date` = '2004-04-12', `university` = 'Đại học Công nghệ Thông tin'
WHERE `email` = 'huy@gmail.com';

UPDATE `users`
SET `birth_date` = '2003-09-18', `university` = 'Đại học Sư phạm Kỹ thuật TP.HCM'
WHERE `email` = 'nam@gmail.com';

UPDATE `users`
SET `birth_date` = '2002-12-03', `university` = 'Đại học Quốc gia TP.HCM'
WHERE `email` = 'hoang@gmail.com';
