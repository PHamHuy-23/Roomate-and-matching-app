# Roommate Hub Project

> ⚠️ **TRẠNG THÁI DỰ ÁN: PROTOTYPE (BẢN MẪU THỬ NGHIỆM - WORK IN PROGRESS)**
>
> Dự án hiện đang trong giai đoạn **Prototype / Thử nghiệm kỹ thuật**, phục vụ mục đích nghiên cứu và phát triển tính năng tìm bạn ở ghép phòng trọ. Các phân hệ Backend và Frontend đang tiếp tục được hoàn thiện và tích hợp.

Ứng dụng kết nối và tìm bạn ở ghép phòng trọ thông minh dành cho sinh viên và người đi làm.
Hệ thống gồm **Frontend Flutter**, **Backend Spring Boot**, cơ sở dữ liệu **PostgreSQL trên Supabase** và lưu ảnh trên **Cloudflare R2**.

---

## 📁 Cấu trúc thư mục

```text
Roomate-and-matching-app/
├── backend/          # RESTful API viết bằng Java Spring Boot 3 + Maven (JDK 21)
├── frontend/         # Ứng dụng Mobile & Web đa nền tảng viết bằng Flutter (Dart)
├── database/         # PostgreSQL schema và dữ liệu mẫu cho Supabase
│   ├── 01_schema.sql         # DDL: Định nghĩa database, các bảng và khóa ngoại
│   ├── 02_seed_data.sql      # DML: Nạp dữ liệu mẫu (users, preferences, posts...)
│   ├── roommate_hub.sql      # File tổng hợp (Schema + Data) chạy 1 bước
│   └── README.md             # Hướng dẫn chi tiết về Database và tài khoản test
├── docs/             # Tài liệu đặc tả, tài liệu thiết kế hệ thống
└── README.md         # Tài liệu hướng dẫn cài đặt và khởi chạy dự án
```

---

## ⚙️ Yêu cầu môi trường (Prerequisites)

Trước khi bắt đầu, hãy đảm bảo máy tính đã cài đặt các công cụ sau:

1. **Java Development Kit (JDK) 21** (Ví dụ: Microsoft OpenJDK 21 hoặc Oracle JDK 21).
2. **Flutter SDK** (Phiên bản `>= 3.20.0`) và **Dart SDK**.
3. **Supabase project** hoặc PostgreSQL 15+.
4. **Android Studio / VS Code** (kèm Flutter & Dart extension).
5. **Cloudflare R2 bucket**, API token và public/custom domain để hiển thị ảnh.

---

## 🚀 Hướng dẫn Cài đặt và Chạy hệ thống

### Bước 1: Khởi tạo PostgreSQL trên Supabase

1. Tạo project Supabase và mở **SQL Editor**.
2. Chạy lần lượt `database/01_schema.sql` và `database/02_seed_data.sql`.
3. Tạo cấu hình local:

   ```bash
   cd backend
   cp .env.example .env
   ```

   Trên Windows PowerShell, dùng `Copy-Item .env.example .env`. Sau đó chỉnh các giá trị trong `backend/.env`:

   ```properties
   DB_URL=jdbc:postgresql://YOUR_POOLER_HOST:5432/postgres?sslmode=require
   DB_USERNAME=postgres.YOUR_PROJECT_REF
   DB_PASSWORD=YOUR_SUPABASE_DATABASE_PASSWORD
   JWT_SECRET=REPLACE_WITH_A_LONG_RANDOM_SECRET
   ```

   Dùng **Session pooler** cho máy IPv4. File `.env` đã được Git ignore; chỉ `.env.example` được commit.

### Bước 2: Cấu hình Cloudflare R2

1. Tạo bucket, ví dụ `roommate-hub`.
2. Tạo R2 API token chỉ có quyền đọc/ghi bucket này.
3. Bật public bucket hoặc gắn custom domain để lấy `R2_PUBLIC_URL`.
4. Áp dụng CORS mẫu tại `docs/cloudflare-r2-cors.json` nếu chạy Flutter Web.
5. Điền `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME` và `R2_PUBLIC_URL` trong `backend/.env`.

R2 secret chỉ nằm ở backend. Flutter xin presigned PUT URL ngắn hạn từ backend rồi upload trực tiếp lên R2.

#### 🔑 Tài khoản mẫu thử nghiệm (Test Accounts)
Tất cả các tài khoản mặc định có mật khẩu là: **`123456`**

| Vai trò | Email đăng nhập | Mật khẩu | Mô tả |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@roommatehub.com` | `123456` | Quản trị viên hệ thống |
| **User** | `huy@gmail.com` | `123456` | Sinh viên tìm bạn ở ghép |
| **User** | `nam@gmail.com` | `123456` | Sinh viên đã đăng bài tìm bạn ở ghép |
| **User** | `hoang@gmail.com` | `123456` | Sinh viên tìm phòng |

---

### Bước 3: Chạy Backend (Spring Boot API)

1. Mở một cửa sổ Terminal mới tại thư mục gốc của dự án.
2. Di chuyển vào thư mục backend:
   ```bash
   cd backend
   ```
3. Chạy ứng dụng bằng Maven Wrapper:
   - **Windows (PowerShell / CMD)**:
     ```powershell
     .\mvnw.cmd spring-boot:run
     ```
   - **macOS / Linux**:
     ```bash
     ./mvnw spring-boot:run
     ```
4. Khi thấy thông báo `Started HubApplication in ... seconds`, API backend đã sẵn sàng tại địa chỉ:  
   `http://localhost:8080`

---

### Bước 4: Chạy Frontend (Flutter)

1. Mở một cửa sổ Terminal khác và di chuyển vào thư mục frontend:
   ```bash
   cd frontend
   ```
2. Cài đặt các package cần thiết:
   ```bash
   flutter pub get
   ```
3. **Cấu hình IP Backend (`API_BASE_URL`)**:
   Truyền địa chỉ API bằng `--dart-define`; không sửa hoặc hard-code IP trong source:
   - **Chạy Web hoặc Windows Desktop**: `http://localhost:8080/api/v1`
   - **Chạy máy ảo Android Emulator**: `http://10.0.2.2:8080/api/v1`
   - **Chạy trên điện thoại thật (cùng mạng Wi-Fi)**: `http://<IP_LAN_MAY_TINH>:8080/api/v1` (VD: `http://192.168.1.10:8080/api/v1`)
4. Khởi chạy ứng dụng:
   - **Chạy trên Web (Edge/Chrome)**:
     ```bash
     flutter run -d edge
     # hoặc
     flutter run -d chrome
     ```
   - **Chạy trên thiết bị di động (Android Emulator hoặc máy thật)**:
     ```powershell
     # Android Emulator
     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

     # Điện thoại thật cùng Wi-Fi với máy chạy backend
     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
     ```

5. **Build APK demo**:
   ```powershell
   # APK dành cho Android Emulator
   flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

   # APK cài trên điện thoại thật; thay IP bằng IP LAN của máy chạy backend
   flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
   ```
   APK được tạo tại `frontend/build/app/outputs/flutter-apk/app-release.apk`. Backend phải đang chạy, cổng `8080` phải truy cập được từ thiết bị và điện thoại phải cùng mạng với máy chủ.

---

## 👥 Tổ chức Dự án & Phân công Nhiệm vụ (All-Dev Core Team)

Dự án được triển khai theo mô hình **All-Dev Core Team**: Tất cả thành viên đều là **Lập trình viên chính (Main Developers)**, trực tiếp tham gia viết mã nguồn và thực hiện mọi công đoạn theo **Vòng đời phát triển phần mềm (SDLC)**. Mỗi bạn đảm nhận vai trò Lead (chịu trách nhiệm đầu mối) cho một mảng chuyên môn và cùng chia sẻ các task lập trình cụ thể:

| Thành viên | MSSV | Vai trò Kỹ thuật | Trách nhiệm chính trong dự án | Bảng Task Cá Nhân |
| :--- | :---: | :--- | :--- | :---: |
| **PM Leader (AI Lead)** | — | Quản lý dự án & Kiến trúc | Lập kế hoạch SDLC, giao task trực tiếp vào Markdown, review code/docs, đồng bộ mã nguồn GitHub. | — |
| **Phạm Quốc Huy** | **24110226** | **Main Fullstack Dev**<br>*(Lead BA & Tài liệu)* | Lead phân tích 54 yêu cầu (FRs) & báo cáo học thuật ([Nhom13_Mohinhhoayeucau.docx](docs/Nhom13_Mohinhhoayeucau.docx)); trực tiếp code Backend UserPreference/Admin và UI Khảo sát tiêu chí/Profile. | [**TASKS_QUOC_HUY.md**](TASKS_QUOC_HUY.md) |
| **Trần Quang Huy** | **24110228** | **Main Fullstack Dev**<br>*(Lead Technical & Prototype)* | Lead kiến trúc hệ thống, cấu hình Spring Boot 3 & Flutter; trực tiếp code Backend Auth/JWT/Matching Engine và UI Auth/Khám phá gợi ý bạn trọ. | [**TASKS_QUANG_HUY.md**](TASKS_QUANG_HUY.md) |
| **Phan Tiến Đạt** | **24110195** | **Main Fullstack Dev**<br>*(Lead Database & QA)* | Lead mô hình hóa CSDL PostgreSQL/Supabase & kế hoạch kiểm thử; trực tiếp code Backend RoomPost/MatchRequest/Lịch hẹn và UI Bài đăng phòng trọ/Lịch hẹn xem phòng. | [**TASKS_TIEN_DAT.md**](TASKS_TIEN_DAT.md) |

> 📌 Toàn bộ bảng phân công chi tiết theo 6 giai đoạn (Yêu cầu -> CSDL & Thiết kế -> Backend -> Frontend -> Tích hợp/QA -> Release), cùng lộ trình Master Schedule (Hạn chót toàn diện: **18:00 ngày 23/09/2026**) được quản lý minh bạch tại: **[TASK_ASSIGNMENTS.md](TASK_ASSIGNMENTS.md)**.  
> 📖 Hướng dẫn phối hợp nhóm qua Git & quy trình giải quyết xung đột (Conflict resolution): **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)**.

---

## 📌 Các lưu ý quan trọng khi phát triển (Troubleshooting)

- **Tránh lỗi .NET khi mở dự án trên VS Code**: Nếu bạn đã cài đặt extension **C# Dev Kit**, extension này có thể quét nhầm các file solution C++ do Flutter Windows build sinh ra. Dự án đã bổ sung cấu hình trong `.vscode/settings.json` để ngăn ngừa tình trạng này. Bạn cũng có thể nhấn chuột phải vào extension *C# Dev Kit* và chọn *Disable (Workspace)*.
- **CORS & Authentication**: Backend đã cấu hình sẵn Spring Security và CORS Filter, cho phép Web Frontend gửi request kèm JWT token mà không bị block.
- **Tự động đồng bộ Schema**: Thuộc tính `spring.jpa.hibernate.ddl-auto=update` được bật để tự động đồng bộ thêm cột hoặc bảng mới khi Entity trong Java thay đổi.
