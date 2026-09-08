CREATE DATABASE IF NOT EXISTS roommate_hub 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE roommate_hub;

-- 1. BẢNG NGƯỜI DÙNG (users)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    gender VARCHAR(10) NOT NULL DEFAULT 'MALE', -- 'MALE', 'FEMALE'
    role VARCHAR(30) NOT NULL DEFAULT 'ROLE_USER', -- 'ROLE_USER', 'ROLE_ADMIN'
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'LOCKED'
    avatar_url VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. BẢNG KHẢO SÁT & TIÊU CHÍ GHÉP ĐÔI (user_preferences)
-- Phục vụ thuật toán 5 tiêu chí: Ngân sách, Thức khuya, Dậy sớm, Sạch sẽ, Hút thuốc
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    budget_min DOUBLE NOT NULL DEFAULT 1000000,
    budget_max DOUBLE NOT NULL DEFAULT 5000000,
    sleep_late BOOLEAN NOT NULL DEFAULT FALSE,
    wake_early BOOLEAN NOT NULL DEFAULT TRUE,
    cleanliness_level INT NOT NULL DEFAULT 3, -- Thang đo từ 1 đến 5
    smoking BOOLEAN NOT NULL DEFAULT FALSE,
    pet_friendly BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_preferences_user FOREIGN KEY (user_id) 
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. BẢNG YÊU CẦU KẾT NỐI (match_requests)
-- Phục vụ cơ chế bảo mật kết nối Double Opt-in
CREATE TABLE IF NOT EXISTS match_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    compatibility_score DOUBLE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'ACCEPTED', 'REJECTED'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_match_requests_sender FOREIGN KEY (sender_id) 
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_match_requests_receiver FOREIGN KEY (receiver_id) 
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT uq_match_request_pair UNIQUE (sender_id, receiver_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. BẢNG BÀI ĐĂNG TÌM BẠN Ở GHÉP (room_posts)
CREATE TABLE IF NOT EXISTS room_posts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    author_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DOUBLE NOT NULL,
    address VARCHAR(255) NOT NULL,
    max_occupants INT NOT NULL DEFAULT 2,
    image_url VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE', -- 'PENDING', 'APPROVED', 'REJECTED', 'AVAILABLE'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_room_posts_author FOREIGN KEY (author_id) 
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- DỮ LIỆU KHỞI TẠO MẪU (SEED DATA)
-- Mật khẩu mặc định của tất cả tài khoản mẫu là: admin123
-- Mã băm BCrypt: $2a$10$wE9mNmsjGg1v211pfnrDduo3/Kj6/F3aWvKkV/bI4o4P2q8e.f6ey
-- -------------------------------------------------------------

-- 1. Thêm tài khoản Admin và sinh viên mẫu
INSERT INTO users (id, email, password, full_name, phone, gender, role, status) VALUES
(1, 'admin@roommatehub.com', '$2a$10$wE9mNmsjGg1v211pfnrDduo3/Kj6/F3aWvKkV/bI4o4P2q8e.f6ey', 'Quản Trị Viên Hệ Thống', '0909000111', 'MALE', 'ROLE_ADMIN', 'ACTIVE'),
(2, 'nguyenvana@gmail.com', '$2a$10$wE9mNmsjGg1v211pfnrDduo3/Kj6/F3aWvKkV/bI4o4P2q8e.f6ey', 'Nguyễn Văn A', '0912345678', 'MALE', 'ROLE_USER', 'ACTIVE'),
(3, 'tranthib@gmail.com', '$2a$10$wE9mNmsjGg1v211pfnrDduo3/Kj6/F3aWvKkV/bI4o4P2q8e.f6ey', 'Trần Thị B', '0987654321', 'FEMALE', 'ROLE_USER', 'ACTIVE'),
(4, 'lequangc@gmail.com', '$2a$10$wE9mNmsjGg1v211pfnrDduo3/Kj6/F3aWvKkV/bI4o4P2q8e.f6ey', 'Lê Quang C', '0933112233', 'MALE', 'ROLE_USER', 'ACTIVE')
ON DUPLICATE KEY UPDATE id=id;

-- 2. Thêm khảo sát lối sống cho các sinh viên mẫu
INSERT INTO user_preferences (user_id, budget_min, budget_max, sleep_late, wake_early, cleanliness_level, smoking, pet_friendly, notes) VALUES
(2, 1500000, 3000000, FALSE, TRUE, 4, FALSE, TRUE, 'Thích yên tĩnh để học bài buổi tối'),
(3, 2000000, 3500000, TRUE, FALSE, 5, FALSE, FALSE, 'Sạch sẽ ngăn nắp, không nuôi động vật'),
(4, 1800000, 3200000, FALSE, TRUE, 4, FALSE, TRUE, 'Hòa đồng, thích tập thể dục buổi sáng')
ON DUPLICATE KEY UPDATE user_id=user_id;

-- 3. Thêm bài đăng phòng mẫu
INSERT INTO room_posts (id, author_id, title, description, price, address, max_occupants, status) VALUES
(1, 2, 'Tìm 1 bạn nam ở ghép phòng trọ gần ĐH SPKT', 'Phòng rộng 25m2, có gác lửng, máy lạnh, giờ giấc tự do, điện 3.5k/kwh, nước 100k/tháng.', 1800000, 'Đường Võ Văn Ngân, Linh Chiểu, TP. Thủ Đức', 2, 'AVAILABLE'),
(2, 4, 'Cần thêm bạn cùng phòng chung cư mini', 'Phòng thoáng mát đầy đủ nội thất tủ lạnh, máy giặt, bếp từ, chỉ cần dọn vào ở.', 2200000, 'Đường Đặng Văn Bi, Trường Thọ, TP. Thủ Đức', 2, 'AVAILABLE')
ON DUPLICATE KEY UPDATE id=id;