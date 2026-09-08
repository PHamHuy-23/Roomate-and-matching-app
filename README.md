# Roommate Hub Project

Dự án Roommate Hub - Ứng dụng tìm người ở ghép (Mobile & Web).
Dự án được cấu trúc lại theo chuẩn: Frontend (Flutter) và Backend (Java Spring Boot).

## Cấu trúc thư mục
- `/backend`: Mã nguồn Java Spring Boot (REST API).
- `/frontend`: Mã nguồn Flutter (Mobile & Web).
- `/database`: Chứa file dump SQL để khởi tạo Database.
- `/docs`: Các tài liệu liên quan đến dự án (Docx, txt...).

## Yêu cầu hệ thống (Requirements)
Để chạy được dự án trên bất kỳ máy nào, bạn cần cài đặt:
1. **Java Development Kit (JDK) 21**: Dành cho Backend.
2. **Flutter SDK** (Phiên bản mới nhất) & Dart: Dành cho Frontend.
3. **MySQL Server**: (Phiên bản 8.0 trở lên) và phần mềm quản lý (như DBeaver, MySQL Workbench).
4. **Android Studio** (Tùy chọn): Nếu bạn muốn build và chạy thử trên máy ảo Android.

## Hướng dẫn cài đặt và chạy hệ thống

### 1. Cài đặt Cơ sở dữ liệu (Database)
1. Mở MySQL / DBeaver / Workbench.
2. Đăng nhập bằng tài khoản `root`.
3. Import (chạy) file `database/roommate_hub.sql` để tạo CSDL.
4. **Cấu hình mật khẩu**: Mở file `backend/src/main/resources/application.properties` và sửa dòng `spring.datasource.password=123456` thành mật khẩu MySQL trên máy của bạn.

### 2. Chạy Backend (Spring Boot API)
1. Mở Terminal / Command Prompt.
2. Di chuyển vào thư mục backend: `cd backend`
3. Chạy lệnh:
   - Trên Windows: `.\mvnw spring-boot:run`
   - Trên Mac/Linux: `./mvnw spring-boot:run`
4. Backend sẽ khởi động và lắng nghe ở cổng `http://localhost:8080`.

### 3. Chạy Frontend (Flutter Mobile/Web)
1. Mở Terminal / Command Prompt khác.
2. Di chuyển vào thư mục frontend: `cd frontend`
3. Cài đặt thư viện: `flutter pub get`
4. **Lưu ý cấu hình API**: 
   - Mở file `frontend/lib/services/api_service.dart`.
   - Tìm biến `baseUrl`. 
   - Nếu chạy trên **Web / Windows Desktop**: Để là `http://localhost:8080/api/v1`.
   - Nếu chạy trên **Máy ảo Android**: Sửa thành `http://10.0.2.2:8080/api/v1`.
   - Nếu chạy trên **Điện thoại thật**: Sửa thành địa chỉ IP LAN của máy tính (VD: `http://192.168.1.5:8080/api/v1`).
5. Chạy ứng dụng:
   - Chạy trên Web (Edge/Chrome): `flutter run -d edge` (hoặc `chrome`).
   - Chạy trên điện thoại/máy ảo: `flutter run`.

## Flow & Testing
- Các chức năng như Đăng nhập, Đăng ký đã được tích hợp CORS để cho phép Frontend (đặc biệt là Web) gọi API mà không bị chặn.
- Việc kết nối tới CSDL sẽ tự động tạo bảng (hibernate ddl-auto=update) và đồng bộ với cấu trúc entity trong Java.
