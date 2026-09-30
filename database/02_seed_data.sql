-- Roommate Hub sample data for PostgreSQL / Supabase.
-- All sample accounts use the password: 123456

BEGIN;

TRUNCATE TABLE
    chat_messages,
    blocked_users,
    reports,
    contact_permissions,
    viewing_appointments,
    match_requests,
    room_posts,
    user_preferences,
    users
RESTART IDENTITY CASCADE;

-- 1. Users
INSERT INTO users
    (id, email, password_hash, full_name, gender, phone, avatar_url,
     birth_date, university, role, status, created_at)
VALUES
    (1, 'huy@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Quang Huy', 'MALE', '0901111222', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
     '2004-04-12', 'Đại học Công nghệ Thông tin', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (2, 'nam@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Văn Nam', 'MALE', '0903333444', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
     '2003-09-18', 'Đại học Sư phạm Kỹ thuật TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (3, 'hoang@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Minh Hoàng', 'MALE', '0905555666', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
     '2002-12-03', 'Đại học Quốc gia TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (4, 'admin@roommatehub.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Quản Trị Viên', 'MALE', '0909000111', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
     '1998-01-01', 'Đại học Bách Khoa TP.HCM', 'ROLE_ADMIN', 'ACTIVE', CURRENT_TIMESTAMP),
    (5, 'thao@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Phương Thảo', 'FEMALE', '0912345678', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
     '2003-05-20', 'Đại học Kinh Tế TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (6, 'linh@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Khánh Linh', 'FEMALE', '0987654321', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
     '2004-10-15', 'Đại học Khoa học Tự nhiên', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (7, 'tuan@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Tuấn Minh', 'MALE', '0933221100', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
     '2003-03-08', 'Đại học Bách Khoa TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (8, 'demo.match.high@roommatehub.local', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Tuấn Minh (Tương thích cao)', 'MALE', '0908000101', 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
     '2004-02-15', 'Đại học Công nghệ Thông tin', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (9, 'demo.match.medium@roommatehub.local', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Hoàng Nam (Tương thích TB)', 'MALE', '0908000102', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
     '2003-08-21', 'Đại học Sư phạm Kỹ thuật TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (10, 'demo.match.low@roommatehub.local', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Gia Bảo (Tương thích thấp)', 'MALE', '0908000103', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
     '2002-11-09', 'Đại học Quốc gia TP.HCM', 'ROLE_USER', 'ACTIVE', CURRENT_TIMESTAMP),
    (11, 'baduser@gmail.com', '$2a$10$6eLwpG/.COtMq/kOX.P5a.wei4wALJDEyMGt.9LIAMdVFhITutW6a',
     'Trần Văn Quậy (Tài khoản bị khóa)', 'MALE', '0999888777', NULL,
     '2001-07-07', 'Đại học Mở TP.HCM', 'ROLE_USER', 'LOCKED', CURRENT_TIMESTAMP);

-- 2. User Preferences
INSERT INTO user_preferences
    (id, user_id, target_district, budget_amount, sleep_habit,
     cleanliness_level, is_smoking, allow_pets, bio_description)
VALUES
    (1, 1, 'Thủ Đức', 2500000, 1, 4, FALSE, FALSE, 'Sinh viên năm 3 IT, hướng nội, chăm học, phòng ngăn nắp.'),
    (2, 2, 'Thủ Đức', 2100000, 1, 4, FALSE, FALSE, 'Sinh viên SPKT, hòa đồng, nấu ăn ngon, thích chơi cầu lông.'),
    (3, 3, 'Thủ Đức', 3500000, 3, 2, TRUE, FALSE, 'Hay thức khuya làm đồ án, vui tính, dễ gần.'),
    (4, 4, 'Bình Thạnh', 4000000, 2, 5, FALSE, TRUE, 'Tài khoản Quản Trị Viên hệ thống Roommate Hub.'),
    (5, 5, 'Quận 10', 2800000, 1, 5, FALSE, TRUE, 'Sinh viên UEH, sạch sẽ tuyệt đối, yêu thích mèo con.'),
    (6, 6, 'Quận 5', 2200000, 2, 4, FALSE, FALSE, 'Sinh viên KHTN, yên tĩnh, không hút thuốc, ít tụ tập.'),
    (7, 7, 'Bình Thạnh', 3000000, 2, 4, FALSE, FALSE, 'Sinh viên Bách Khoa năm 4, điềm đạm, nếp sống lành mạnh.'),
    (8, 8, 'Thủ Đức', 2600000, 1, 4, FALSE, FALSE, 'Thói quen sống giống bạn: ngủ sớm, sạch sẽ, không thuốc lá.'),
    (9, 9, 'Thủ Đức', 3200000, 2, 3, FALSE, FALSE, 'Nếp sống linh hoạt, dễ tính, hay sinh hoạt câu lạc bộ.'),
    (10, 10, 'Thủ Đức', 4500000, 3, 1, TRUE, TRUE, 'Cú đêm làm việc, nuôi thú cưng và có hút thuốc lá.'),
    (11, 11, 'Gò Vấp', 1500000, 3, 1, TRUE, TRUE, 'Tài khoản vi phạm quy tắc cộng đồng (đã bị admin khóa).');

-- 3. Room Posts
INSERT INTO room_posts
    (id, author_id, title, description, price, address, district, deposit,
     electricity_water_cost, area, max_occupants, current_occupants,
     amenities, image_url, status, created_at)
VALUES
    (1, 2, 'Tìm 1 bạn nam ở ghép phòng trọ gần ĐH Sư Phạm Kỹ Thuật',
     'Phòng rộng 25m2, có gác lửng, máy lạnh, ban công thoáng mát. Vị trí an ninh, gần chợ Bắc Ninh và trạm bus. Cần tìm 1 bạn nam sạch sẽ, không hút thuốc.',
     1800000, 'Đường số 6, Linh Trung, TP. Thủ Đức', 'Thủ Đức', 1800000, 300000, 25.0, 2, 1,
     'Wifi,Máy lạnh,Chỗ để xe,Gác lửng,Tủ lạnh',
     'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (2, 5, 'Phòng trọ cao cấp full nội thất gần ĐH Kinh Tế - Quận 10',
     'Phòng mới xây 100%, có máy giặt riêng, bếp nấu ăn, thang máy, khóa vân tay an ninh. Cần tìm 1 bạn nữ ở ghép để chia đôi tiền phòng.',
     2600000, 'Cách Mạng Tháng 8, Phường 13, Quận 10', 'Quận 10', 2600000, 350000, 30.0, 2, 1,
     'Máy lạnh,Tủ lạnh,Máy giặt,Thang máy,Wifi,Khóa vân tay,Ban công',
     'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (3, 7, 'Studio ban công cực thoáng gần ĐH Hutech & Ngoại Thương - Bình Thạnh',
     'Studio có gác cao 1m8, cửa sổ đón nắng sớm. Đầy đủ tiện nghi: tủ lạnh, máy lạnh inverter tiết kiệm điện. Phù hợp sinh viên hoặc người mới đi làm.',
     3200000, '48 Điện Biên Phủ, Phường 25, Bình Thạnh', 'Bình Thạnh', 3200000, 400000, 32.0, 2, 1,
     'Máy lạnh,Tủ lạnh,Kệ bếp,Ban công,Máy giặt riêng,Bảo vệ 24/7',
     'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (4, 1, 'Tìm bạn nam ghép phòng chung cư KTX ĐHQG - Thủ Đức',
     'Căn hộ chung cư mini lầu 4, view đẹp, thoáng gió tự nhiên, giờ giấc hoàn toàn tự do. Đã có sẵn nệm, bàn học, máy giặt chung.',
     1500000, 'Đường Tân Lập, Đông Hòa, Dĩ An (Khu ĐHQG Thủ Đức)', 'Thủ Đức', 1500000, 250000, 28.0, 2, 1,
     'Wifi,Chỗ để xe,Giờ giấc tự do,Máy giặt,Ban công',
     'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (5, 6, 'Phòng ghép nữ sạch sẽ, an ninh gần ĐH Khoa học Tự Nhiên - Quận 5',
     'Nhà riêng nguyên căn, phòng ở lầu 1 có ban công riêng. Khu dân trí cao, yên tĩnh học tập. Gần trạm xe buýt và các trường ĐH lớn Quận 5.',
     2000000, '227 Nguyễn Văn Cừ, Phường 4, Quận 5', 'Quận 5', 2000000, 250000, 22.0, 2, 1,
     'Wifi,Máy lạnh,Chỗ nấu ăn,Camera an ninh,Sân thượng',
     'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (6, 3, 'Tìm 1 bạn ở ghép phòng trọ Gò Vấp - gần ĐH Công Nghiệp IUH',
     'Phòng trọ có gác lửng đúc kiên cố, wc riêng khép kín, có chỗ nấu ăn thoải mái. Bạn cùng phòng vui vẻ, dễ tính.',
     1700000, 'Đường số 8, Phường 11, Gò Vấp', 'Gò Vấp', 1700000, 300000, 24.0, 2, 1,
     'Wifi,Chỗ để xe,Gác lửng,Giờ giấc tự do',
     'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800',
     'AVAILABLE', CURRENT_TIMESTAMP),

    (7, 2, '[Chờ duyệt] Cho thuê phòng ghép sinh viên khu vực Tân Bình',
     'Phòng gần ngã tư Bảy Hiền, tiện đi lại Quận 10, Tân Bình, Phú Nhuận. Phòng mới sơn sửa lại sạch đẹp.',
     2200000, 'Hoàng Văn Thụ, Phường 4, Tân Bình', 'Tân Bình', 2200000, 300000, 26.0, 2, 0,
     'Wifi,Máy giặt,Camera an ninh',
     'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
     'PENDING', CURRENT_TIMESTAMP),

    (8, 7, '[Chờ duyệt] Tìm bạn nữ cùng phòng chung cư Masteri Thảo Điền',
     'Căn hộ 2 phòng ngủ cao cấp, đầy đủ tiện ích resort, hồ bơi, phòng gym miễn phí. Cần tìm bạn nữ sinh hoạt văn minh, gọn gàng.',
     4500000, 'Xa Lộ Hà Nội, Thảo Điền, TP. Thủ Đức', 'Thủ Đức', 4500000, 500000, 68.0, 3, 2,
     'Hồ bơi,Phòng gym,Máy lạnh,Tủ lạnh,Máy giặt,Thang máy,Bảo vệ 24/7',
     'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
     'PENDING', CURRENT_TIMESTAMP);

-- 4. Match Requests
INSERT INTO match_requests
    (id, sender_id, receiver_id, match_score, status, created_at)
VALUES
    (1, 1, 2, 88.5, 'ACCEPTED', CURRENT_TIMESTAMP),
    (2, 7, 1, 94.0, 'PENDING', CURRENT_TIMESTAMP),
    (3, 3, 1, 52.0, 'PENDING', CURRENT_TIMESTAMP),
    (4, 2, 3, 38.0, 'REJECTED', CURRENT_TIMESTAMP),
    (5, 5, 6, 82.0, 'ACCEPTED', CURRENT_TIMESTAMP);

-- 5. Viewing Appointments
INSERT INTO viewing_appointments
    (id, requester_id, host_id, room_post_id, appointment_time, status, note, created_at)
VALUES
    (1, 1, 2, 2, CURRENT_TIMESTAMP + INTERVAL '1 day', 'PENDING', 'Mình muốn xem phòng cùng một người bạn.', CURRENT_TIMESTAMP),
    (2, 3, 2, 2, CURRENT_TIMESTAMP + INTERVAL '2 days', 'CONFIRMED', 'Xem phòng vào buổi sáng lúc 9h nhé.', CURRENT_TIMESTAMP);

-- 6. Reports
INSERT INTO reports
    (id, reporter_id, target_id, target_type, reason, status, action_note, created_at)
VALUES
    (1, 1, 2, 'ROOM_POST', 'Thông tin phòng không đúng thực tế', 'PENDING', NULL, CURRENT_TIMESTAMP - INTERVAL '15 minutes'),
    (2, 2, 3, 'USER', 'Nội dung tin nhắn không phù hợp quy tắc ứng xử', 'PENDING', NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
    (3, 3, 4, 'ROOM_POST', 'Tin đăng có dấu hiệu trùng lặp', 'RESOLVED', 'Đã đối chiếu với tin RH-024 và xử lý.', CURRENT_TIMESTAMP - INTERVAL '1 day');

-- 7. Chat Messages
INSERT INTO chat_messages
    (id, sender_id, receiver_id, content, is_read, created_at)
VALUES
    (1, 2, 1, 'Chào Huy! Bạn muốn xem phòng vào chiều thứ Hai phải không?', true, CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
    (2, 1, 2, 'Đúng rồi, khoảng 14:00 nhé. Phòng có chỗ để xe không bạn?', true, CURRENT_TIMESTAMP - INTERVAL '20 minutes'),
    (3, 2, 1, 'Có nhé, chỗ để xe rộng rãi và có camera an ninh 24/7.', false, CURRENT_TIMESTAMP - INTERVAL '10 minutes');

-- 8. Synchronize Sequences
SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1)) FROM users;
SELECT setval(pg_get_serial_sequence('user_preferences', 'id'), COALESCE(MAX(id), 1)) FROM user_preferences;
SELECT setval(pg_get_serial_sequence('room_posts', 'id'), COALESCE(MAX(id), 1)) FROM room_posts;
SELECT setval(pg_get_serial_sequence('match_requests', 'id'), COALESCE(MAX(id), 1)) FROM match_requests;
SELECT setval(pg_get_serial_sequence('viewing_appointments', 'id'), COALESCE(MAX(id), 1)) FROM viewing_appointments;
SELECT setval(pg_get_serial_sequence('reports', 'id'), COALESCE(MAX(id), 1)) FROM reports;
SELECT setval(pg_get_serial_sequence('chat_messages', 'id'), COALESCE(MAX(id), 1)) FROM chat_messages;

COMMIT;
