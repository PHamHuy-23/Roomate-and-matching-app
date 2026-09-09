# Roommate Hub - Hướng dẫn Cài đặt Cơ sở dữ liệu (Database)

Thư mục này chứa toàn bộ các script SQL để thiết kế bảng và nạp dữ liệu mẫu cho hệ thống Roommate Hub (MySQL 8.0+).

## Cấu trúc thư mục

- `01_schema.sql`: Chứa mã DDL tạo Database `roommate_hub`, 4 bảng chính (`users`, `user_preferences`, `room_posts`, `match_requests`), các ràng buộc khóa ngoại (Foreign Keys) và chỉ mục (Indexes).
- `02_seed_data.sql`: Chứa mã DML nạp dữ liệu mẫu bao gồm tài khoản Admin, tài khoản sinh viên, khảo sát phong cách sống, bài đăng tìm phòng trọ và yêu cầu kết nối ghép đôi.
- `roommate_hub.sql`: File SQL trọn gói (gồm cả Schema và Seed Data) giúp khởi tạo CSDL hoàn chỉnh chỉ với 1 lần thực thi.

---

## Danh sách tài khoản thử nghiệm (Test Credentials)

Tất cả tài khoản mẫu bên dưới đều sử dụng chung mật khẩu đăng nhập: **`123456`**

| Vai trò | Họ và tên | Email đăng nhập | Mật khẩu | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | Quản Trị Viên | `admin@roommatehub.com` | `123456` | `ACTIVE` |
| **User** | Quang Huy | `huy@gmail.com` | `123456` | `ACTIVE` |
| **User** | Văn Nam | `nam@gmail.com` | `123456` | `ACTIVE` |
| **User** | Minh Hoàng | `hoang@gmail.com` | `123456` | `ACTIVE` |

---

## Hướng dẫn Import vào MySQL

### Cách 1: Sử dụng MySQL Command Line (Khuyến nghị)
Mở Terminal hoặc Command Prompt và chạy lệnh sau (nhập mật khẩu MySQL root khi được yêu cầu):

```bash
mysql -u root -p < database/roommate_hub.sql
```

Hoặc chạy tuần tự 2 file:
```bash
mysql -u root -p < database/01_schema.sql
mysql -u root -p < database/02_seed_data.sql
```

### Cách 2: Sử dụng DBeaver / MySQL Workbench / phpMyAdmin
1. Mở công cụ quản lý CSDL (DBeaver hoặc MySQL Workbench).
2. Tạo một kết nối mới tới MySQL Server của bạn (port mặc định `3306`).
3. Mở file `database/roommate_hub.sql` (File -> Open File...).
4. Chọn **Execute SQL Script** (hoặc tổ hợp phím `Ctrl + Alt + X` trên DBeaver, `Ctrl + Shift + Enter` trên Workbench).
5. Refresh lại danh sách Database, bạn sẽ thấy CSDL `roommate_hub` cùng 4 bảng và dữ liệu mẫu đầy đủ.

---

## Cấu hình kết nối trên Backend (Spring Boot)

Mở file `backend/src/main/resources/application.properties` và điều chỉnh thông số phù hợp với máy tính của bạn:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/roommate_hub?createDatabaseIfNotExists=true&useSSL=false&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=123456
```
*(Lưu ý: Thay `123456` bằng mật khẩu MySQL của bạn nếu khác).*
