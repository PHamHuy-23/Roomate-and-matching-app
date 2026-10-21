-- PostgreSQL / Supabase Migration: Mở rộng image_url và cập nhật 4 ảnh thực tế cho các bài đăng phòng
-- Ngày tạo: 2026-10-06
-- Mục đích: Cho phép lưu nhiều URL ảnh (phân tách bởi dấu phẩy) và cập nhật 4 ảnh nội thất Unsplash thực tế cho bài đăng phòng ID 1-8.

BEGIN;

-- 1. Mở rộng độ dài cột image_url lên VARCHAR(1000)
ALTER TABLE room_posts ALTER COLUMN image_url TYPE VARCHAR(1000);

-- 2. Cập nhật 4 ảnh Unsplash chất lượng cao cho các bài đăng phòng mẫu (ID 1 -> 8)
UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800,https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800,https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800,https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800'
WHERE id = 1;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800,https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800,https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800,https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800'
WHERE id = 2;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800,https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=800,https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800,https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=800'
WHERE id = 3;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=800,https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800,https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800,https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=800'
WHERE id = 4;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800,https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800,https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800,https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800'
WHERE id = 5;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=800,https://images.unsplash.com/photo-1616137466211-f939a420be84?w=800,https://images.unsplash.com/photo-1615873968403-89e068629265?w=800,https://images.unsplash.com/photo-1615529182904-14819c35db37?w=800'
WHERE id = 6;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=800,https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800,https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=800,https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?w=800'
WHERE id = 7;

UPDATE room_posts
SET image_url = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800,https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800,https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800,https://images.unsplash.com/photo-1600573472591-ee6b68d14c68?w=800'
WHERE id = 8;

COMMIT;
