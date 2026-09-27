-- Roommate Hub sample data for PostgreSQL / Supabase.
-- All sample accounts use the password: 123456

BEGIN;

TRUNCATE TABLE
    reports,
    contact_permissions,
    viewing_appointments,
    match_requests,
    room_posts,
    user_preferences,
    users
RESTART IDENTITY CASCADE;

INSERT INTO users
    (id, email, password_hash, full_name, gender, phone, avatar_url,
     birth_date, university, role, status, created_at)
VALUES
    (1, 'huy@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei',
     'Quang Huy', 'MALE', '0970780778', NULL, '2004-04-12',
     'Đại học Công nghệ Thông tin', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (2, 'nam@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei',
     'Văn Nam', 'MALE', '0903333444', NULL, '2003-09-18',
     'Đại học Sư phạm Kỹ thuật TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (3, 'hoang@gmail.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei',
     'Minh Hoàng', 'MALE', '0905555666', NULL, '2002-12-03',
     'Đại học Quốc gia TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (4, 'admin@roommatehub.com', '$2a$10$Xoa9wWbWB5Xdkab/KRjTQeP7D7BpBfKrPJ2wIrjE1L4nZ5yRPWGei',
     'Quản Trị Viên', 'MALE', '0909000111', NULL, NULL, NULL,
     'ROLE_ADMIN', 'ACTIVE', CURRENT_TIMESTAMP);

INSERT INTO user_preferences
    (id, user_id, target_district, budget_amount, sleep_habit,
     cleanliness_level, is_smoking, allow_pets, bio_description)
VALUES
    (1, 1, 'Quận 5', 2500000, 3, 4, FALSE, FALSE,
     'Sinh viên năm 3 IT, chăm chỉ, yên tĩnh.'),
    (2, 2, 'Thủ Đức', 2100000, 1, 4, FALSE, FALSE,
     'Hòa đồng, thích học nhóm.'),
    (3, 3, 'Thủ Đức', 3500000, 3, 2, TRUE, FALSE,
     'Hay thức khuya chơi game.');

INSERT INTO room_posts
    (id, author_id, title, description, price, address, district, deposit,
     electricity_water_cost, area, max_occupants, current_occupants,
     amenities, image_url, status, created_at)
VALUES
    (1, 2, 'Tìm 1 bạn nam ở ghép phòng trọ gần ĐH Sư Phạm Kỹ Thuật',
     'Phòng rộng 25m2, có gác lửng, máy lạnh, ban công thoáng mát.',
     1800000, 'Đường số 6, Linh Trung, TP. Thủ Đức', 'Thủ Đức', 1800000,
     300000, 25, 2, 1, 'Wifi,Máy lạnh,Chỗ để xe', NULL, 'AVAILABLE', CURRENT_TIMESTAMP),
    (2, 1, 'Tìm 1 bạn nữ ở ghép phòng trọ Thủ Đức',
     'Phòng thoáng mát, gần trạm xe buýt, an ninh tốt.',
     1500000, 'Khu phố 2, Phường Linh Trung, TP. Thủ Đức', 'Thủ Đức', 1500000,
     250000, 22, 2, 1, 'Wifi,Máy giặt', NULL, 'AVAILABLE', CURRENT_TIMESTAMP);

INSERT INTO match_requests
    (id, sender_id, receiver_id, match_score, status, created_at)
VALUES
    (1, 1, 2, 85.2, 'ACCEPTED', CURRENT_TIMESTAMP),
    (2, 2, 3, 38.0, 'PENDING', CURRENT_TIMESTAMP);

SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1)) FROM users;
SELECT setval(pg_get_serial_sequence('user_preferences', 'id'), COALESCE(MAX(id), 1)) FROM user_preferences;
SELECT setval(pg_get_serial_sequence('room_posts', 'id'), COALESCE(MAX(id), 1)) FROM room_posts;
SELECT setval(pg_get_serial_sequence('match_requests', 'id'), COALESCE(MAX(id), 1)) FROM match_requests;

COMMIT;
