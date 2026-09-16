-- =============================================================================
-- ROOMMATE HUB - MIGRATION: NGAY SINH VA TRUONG DAI HOC
-- Chay file nay mot lan cho database da duoc tao truoc thay doi QH2-4.2.
-- Database khoi tao moi bang 01_schema.sql hoac roommate_hub.sql khong can chay.
-- =============================================================================

USE `roommate_hub`;

ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `birth_date` DATE DEFAULT NULL AFTER `avatar_url`,
    ADD COLUMN IF NOT EXISTS `university` VARCHAR(150) DEFAULT NULL AFTER `birth_date`;

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
