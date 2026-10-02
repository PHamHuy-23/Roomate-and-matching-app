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

`01_schema.sql` dùng để tạo database mới và sẽ xóa dữ liệu cũ trước khi tạo lại bảng. Với project Supabase đã có dữ liệu, **không chạy lại** `01_schema.sql` hoặc `02_seed_data.sql`; chỉ chạy các migration PostgreSQL cần thiết theo thứ tự:

1. `migrations/20260930_moderation_reason.sql` nếu chưa chạy: bổ sung trạng thái tìm kiếm, tiêu chí ghép đôi, lý do kiểm duyệt, ảnh bằng chứng và danh sách tin đã lưu.
2. `migrations/20261001_match_request_version.sql`: bổ sung cột `match_requests.version` cho cơ chế khóa lạc quan (`@Version`) của backend. Migration điền `0` cho các dòng thiếu version, giữ nguyên version khác `NULL`, đặt mặc định `0` và không cho phép `NULL`. Có thể chạy lại migration này mà không đặt lại version hoặc xóa lời mời hiện có.
3. `migrations/20261002_survey_preferences.sql`: bổ sung `move_in_date`, `room_type`, `work_schedule`, `personal_value` vào `user_preferences` để lưu các lựa chọn khảo sát trước đây chỉ có trên giao diện. Các cột cho phép `NULL`, không gán ngày hoặc lựa chọn giả cho bản ghi cũ. Migration chỉ bổ sung cấu trúc/ràng buộc, không xóa dữ liệu và có thể chạy lại. Chạy trước khi khởi động backend phiên bản nhóm 6. Backend/Flutter cũ không gửi các trường mới sẽ giữ nguyên giá trị đã lưu; `NULL` cũng được hiểu là không cập nhật, không phải yêu cầu xóa.

Trước khi nâng cấp, sao lưu dữ liệu và dừng backend. Mở **SQL Editor**, dán toàn bộ nội dung từng migration rồi **Run**; chỉ chuyển sang file tiếp theo khi file trước đã thành công. Khởi động lại backend sau khi migration hoàn tất. Không cần tạo lại project Supabase.

Database mới tạo bằng `01_schema.sql` hiện tại đã có cột version, không cần chạy riêng migration version. Không dựa vào `JPA_DDL_AUTO=update` để sửa dữ liệu version của các dòng cũ. File `20260916_add_user_academic_profile.sql` là migration MySQL cũ, **không chạy trên Supabase**.

Database mới tạo bằng `01_schema.sql` hiện tại cũng đã có bốn cột khảo sát, không cần chạy riêng migration `20261002_survey_preferences.sql`. Project Supabase hiện có chỉ chạy migration mới nếu các migration trước đã chạy thành công; không chạy lại schema/seed.

Nếu cần chuyển dữ liệu thật từ hệ thống khác, export dữ liệu thành CSV rồi import theo thứ tự: `users`, `user_preferences`, `room_posts`, `match_requests`.
