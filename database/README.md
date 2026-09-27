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

Schema PostgreSQL là nguồn sự thật mới. Các file cũ trong `database/migrations/` được viết cho MySQL và không được chạy trên Supabase. Nếu cần chuyển dữ liệu thật từ MySQL, export dữ liệu thành CSV rồi import theo thứ tự: `users`, `user_preferences`, `room_posts`, `match_requests`.
