# Roommate Hub — PostgreSQL / Supabase

`01_schema.sql` và `02_seed_data.sql` dùng cú pháp PostgreSQL 15+ và có thể chạy trực tiếp trong Supabase SQL Editor.

## Khởi tạo Supabase

1. Tạo project Supabase.
2. Mở **SQL Editor**, chạy `01_schema.sql`.
3. Chạy `02_seed_data.sql` nếu cần tài khoản demo.
4. Trong **Connect**, chọn **Session pooler** nếu backend chạy trên mạng IPv4.
5. Chép host, username và database password vào `backend/.env`.

Ví dụ JDBC:

```properties
DB_URL=jdbc:postgresql://YOUR_POOLER_HOST:5432/postgres?sslmode=require
DB_USERNAME=postgres.YOUR_PROJECT_REF
DB_PASSWORD=YOUR_SUPABASE_DATABASE_PASSWORD
```

Không đưa database password hoặc Supabase service-role key vào Flutter.

## Tài khoản demo

Mật khẩu chung: `123456`.

| Vai trò | Email |
|---|---|
| Admin | `admin@roommatehub.com` |
| User | `huy@gmail.com` |
| User | `nam@gmail.com` |
| User | `hoang@gmail.com` |

## Lưu ý migration

`01_schema.sql` dùng để tạo database mới và sẽ xóa dữ liệu cũ trước khi tạo lại bảng. Với project Supabase đã có dữ liệu, **không chạy lại** file này; chỉ chạy migration PostgreSQL `20260930_moderation_reason.sql`. File `20260916_add_user_academic_profile.sql` là migration MySQL cũ, không được chạy trên Supabase. Migration mới bổ sung trạng thái tìm kiếm, tiêu chí ghép đôi có kiểu dữ liệu, lý do kiểm duyệt, ảnh bằng chứng và danh sách tin đã lưu mà không xóa dữ liệu hiện có.

Nếu cần chuyển dữ liệu thật từ hệ thống khác, export dữ liệu thành CSV rồi import theo thứ tự: `users`, `user_preferences`, `room_posts`, `match_requests`.
