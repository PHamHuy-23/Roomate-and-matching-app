-- Roommate Hub discovery-feed sample data for PostgreSQL / Supabase.
-- Run after 01_schema.sql and 02_seed_data.sql.
-- The script is idempotent and derives the candidates from huy@gmail.com.

BEGIN;

WITH source_user AS (
    SELECT u.password_hash, u.gender
    FROM users u
    WHERE u.email = 'huy@gmail.com'
), candidates(email, full_name, phone, birth_date, university) AS (
    VALUES
        ('demo.match.high@roommatehub.local', 'Tuấn Minh', '0908000101',
         DATE '2004-02-15', 'Đại học Công nghệ Thông tin'),
        ('demo.match.medium@roommatehub.local', 'Hoàng Nam', '0908000102',
         DATE '2003-08-21', 'Đại học Sư phạm Kỹ thuật TP.HCM'),
        ('demo.match.low@roommatehub.local', 'Gia Bảo', '0908000103',
         DATE '2002-11-09', 'Đại học Quốc gia TP.HCM')
)
INSERT INTO users
    (email, password_hash, full_name, gender, phone, birth_date, university,
     role, status)
SELECT c.email, s.password_hash, c.full_name, s.gender, c.phone, c.birth_date,
       c.university, 'ROLE_USER', 'ACTIVE'
FROM candidates c
CROSS JOIN source_user s
ON CONFLICT (email) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    gender = EXCLUDED.gender,
    phone = EXCLUDED.phone,
    birth_date = EXCLUDED.birth_date,
    university = EXCLUDED.university;

WITH source_preference AS (
    SELECT p.target_district, p.budget_amount, p.sleep_habit,
           p.cleanliness_level, p.is_smoking, p.allow_pets
    FROM user_preferences p
    JOIN users u ON u.id = p.user_id
    WHERE u.email = 'huy@gmail.com'
), candidate_preferences AS (
    SELECT u.id AS candidate_id, u.email, s.*
    FROM users u
    CROSS JOIN source_preference s
    WHERE u.email LIKE 'demo.match.%@roommatehub.local'
)
INSERT INTO user_preferences
    (user_id, target_district, budget_amount, sleep_habit,
     cleanliness_level, is_smoking, allow_pets, bio_description)
SELECT
    candidate_id,
    target_district,
    CASE
        WHEN email = 'demo.match.high@roommatehub.local' THEN ROUND((budget_amount * 1.05)::numeric)::double precision
        WHEN email = 'demo.match.medium@roommatehub.local' THEN ROUND((budget_amount * 1.5)::numeric)::double precision
        ELSE ROUND((budget_amount * 2)::numeric)::double precision
    END,
    CASE
        WHEN email = 'demo.match.high@roommatehub.local' THEN sleep_habit
        WHEN email = 'demo.match.medium@roommatehub.local' THEN
            CASE WHEN sleep_habit = 1 THEN 2 WHEN sleep_habit = 2 THEN 1 ELSE 2 END
        ELSE CASE WHEN sleep_habit = 1 THEN 3 ELSE 1 END
    END,
    CASE
        WHEN email = 'demo.match.high@roommatehub.local' THEN cleanliness_level
        WHEN email = 'demo.match.medium@roommatehub.local' THEN
            CASE WHEN cleanliness_level >= 3 THEN cleanliness_level - 2 ELSE cleanliness_level + 2 END
        ELSE CASE WHEN cleanliness_level >= 3 THEN 1 ELSE 5 END
    END,
    CASE WHEN email = 'demo.match.low@roommatehub.local' THEN NOT is_smoking ELSE is_smoking END,
    CASE WHEN email = 'demo.match.low@roommatehub.local' THEN NOT allow_pets ELSE allow_pets END,
    CASE
        WHEN email = 'demo.match.high@roommatehub.local'
            THEN 'Dữ liệu mẫu: giờ giấc, ngân sách và nếp sống rất tương đồng.'
        WHEN email = 'demo.match.medium@roommatehub.local'
            THEN 'Dữ liệu mẫu: có vài khác biệt để kiểm tra phần điểm cần lưu ý.'
        ELSE 'Dữ liệu mẫu: khác biệt lớn về giờ giấc và thói quen sinh hoạt.'
    END
FROM candidate_preferences
ON CONFLICT (user_id) DO UPDATE SET
    target_district = EXCLUDED.target_district,
    budget_amount = EXCLUDED.budget_amount,
    sleep_habit = EXCLUDED.sleep_habit,
    cleanliness_level = EXCLUDED.cleanliness_level,
    is_smoking = EXCLUDED.is_smoking,
    allow_pets = EXCLUDED.allow_pets,
    bio_description = EXCLUDED.bio_description;

COMMIT;

SELECT u.id, u.full_name, u.birth_date, u.university, u.email,
       p.target_district, p.budget_amount, p.sleep_habit,
       p.cleanliness_level, p.is_smoking, p.allow_pets
FROM users u
JOIN user_preferences p ON p.user_id = u.id
WHERE u.email LIKE 'demo.match.%@roommatehub.local'
ORDER BY u.email;

-- Cleanup if needed (preferences are removed by ON DELETE CASCADE):
-- DELETE FROM users WHERE email LIKE 'demo.match.%@roommatehub.local';
