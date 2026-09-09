# Roommate Hub Project

> ⚠️ **TRẠNG THÁI DỰ ÁN: PROTOTYPE (BẢN MẪU THỬ NGHIỆM - WORK IN PROGRESS)**
>
> Dự án hiện đang trong giai đoạn **Prototype / Thử nghiệm kỹ thuật**, phục vụ mục đích nghiên cứu và phát triển tính năng tìm bạn ở ghép phòng trọ. Các phân hệ Backend và Frontend đang tiếp tục được hoàn thiện và tích hợp.

Ứng dụng kết nối và tìm bạn ở ghép phòng trọ thông minh dành cho sinh viên và người đi làm.
Hệ thống được thiết kế theo kiến trúc chuẩn gồm **Frontend (Flutter)** và **Backend (Java Spring Boot REST API)**, kết hợp cơ sở dữ liệu **MySQL**.

---

## 📁 Cấu trúc thư mục

```text
Roomate-and-matching-app/
├── backend/          # RESTful API viết bằng Java Spring Boot 3 + Maven (JDK 21)
├── frontend/         # Ứng dụng Mobile & Web đa nền tảng viết bằng Flutter (Dart)
├── database/         # Toàn bộ SQL Scripts thiết kế CSDL và dữ liệu mẫu (MySQL)
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
3. **MySQL Server 8.0+** (kèm công cụ như DBeaver, MySQL Workbench, hoặc CLI).
4. **Android Studio / VS Code** (kèm Flutter & Dart extension).

---

## 🚀 Hướng dẫn Cài đặt và Chạy hệ thống

### Bước 1: Khởi tạo Cơ sở dữ liệu (MySQL)

1. Khởi động dịch vụ MySQL trên máy tính của bạn.
2. Mở terminal hoặc công cụ quản lý CSDL (DBeaver / Workbench) và chạy file SQL khởi tạo:
   - **Cách nhanh qua Command Line**:
     ```bash
     mysql -u root -p < database/roommate_hub.sql
     ```
   - **Hoặc qua DBeaver / Workbench**: Mở file `database/roommate_hub.sql` và thực thi toàn bộ script (`Ctrl + Alt + X` hoặc `Ctrl + Shift + Enter`).
3. Cấu hình mật khẩu DB: Mở file `backend/src/main/resources/application.properties` và chỉnh sửa mật khẩu MySQL nếu máy của bạn khác `123456`:
   ```properties
   spring.datasource.url=jdbc:mysql://localhost:3306/roommate_hub?createDatabaseIfNotExists=true&useSSL=false&serverTimezone=UTC
   spring.datasource.username=root
   spring.datasource.password=123456
   ```

#### 🔑 Tài khoản mẫu thử nghiệm (Test Accounts)
Tất cả các tài khoản mặc định có mật khẩu là: **`123456`**

| Vai trò | Email đăng nhập | Mật khẩu | Mô tả |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@roommatehub.com` | `123456` | Quản trị viên hệ thống |
| **User** | `huy@gmail.com` | `123456` | Sinh viên tìm bạn ở ghép |
| **User** | `nam@gmail.com` | `123456` | Sinh viên đã đăng bài tìm bạn ở ghép |
| **User** | `hoang@gmail.com` | `123456` | Sinh viên tìm phòng |

---

### Bước 2: Chạy Backend (Spring Boot API)

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

### Bước 3: Chạy Frontend (Flutter)

1. Mở một cửa sổ Terminal khác và di chuyển vào thư mục frontend:
   ```bash
   cd frontend
   ```
2. Cài đặt các package cần thiết:
   ```bash
   flutter pub get
   ```
3. **Cấu hình IP Backend (`baseUrl`)**:
   Mở file `frontend/lib/services/api_service.dart` và kiểm tra cấu hình địa chỉ API phù hợp với môi trường chạy:
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
     ```bash
     flutter run
     ```

---

## 👥 Tổ chức Dự án & Phân công Nhiệm vụ (All-Dev Core Team)

Dự án được triển khai theo mô hình **All-Dev Core Team**: Tất cả thành viên đều là **Lập trình viên chính (Main Developers)**, trực tiếp tham gia viết mã nguồn và thực hiện mọi công đoạn theo **Vòng đời phát triển phần mềm (SDLC)**. Mỗi bạn đảm nhận vai trò Lead (chịu trách nhiệm đầu mối) cho một mảng chuyên môn và cùng chia sẻ các task lập trình cụ thể:

| Thành viên | MSSV | Vai trò Kỹ thuật | Trách nhiệm chính trong dự án | Bảng Task Cá Nhân |
| :--- | :---: | :--- | :--- | :---: |
| **PM Leader (AI Lead)** | — | Quản lý dự án & Kiến trúc | Lập kế hoạch SDLC, giao task trực tiếp vào Markdown, review code/docs, đồng bộ mã nguồn GitHub. | — |
| **Phạm Quốc Huy** | **24110226** | **Main Fullstack Dev**<br>*(Lead BA & Tài liệu)* | Lead phân tích 54 yêu cầu (FRs) & báo cáo học thuật ([Nhom13_Mohinhhoayeucau.docx](docs/Nhom13_Mohinhhoayeucau.docx)); trực tiếp code Backend UserPreference/Admin và UI Khảo sát tiêu chí/Profile. | [**TASKS_QUOC_HUY.md**](TASKS_QUOC_HUY.md) |
| **Trần Quang Huy** | **24110228** | **Main Fullstack Dev**<br>*(Lead Technical & Prototype)* | Lead kiến trúc hệ thống, cấu hình Spring Boot 3 & Flutter; trực tiếp code Backend Auth/JWT/Matching Engine và UI Auth/Khám phá gợi ý bạn trọ. | [**TASKS_QUANG_HUY.md**](TASKS_QUANG_HUY.md) |
| **Phan Tiến Đạt** | **24110195** | **Main Fullstack Dev**<br>*(Lead Database & QA)* | Lead mô hình hóa CSDL MySQL & kế hoạch kiểm thử; trực tiếp code Backend RoomPost/MatchRequest/Lịch hẹn và UI Bài đăng phòng trọ/Lịch hẹn xem phòng. | [**TASKS_TIEN_DAT.md**](TASKS_TIEN_DAT.md) |

> 📌 Toàn bộ bảng phân công chi tiết theo 6 giai đoạn (Yêu cầu -> CSDL & Thiết kế -> Backend -> Frontend -> Tích hợp/QA -> Release), cùng lộ trình Master Schedule (Hạn chót toàn diện: **18:00 ngày 23/09/2026**) được quản lý minh bạch tại: **[TASK_ASSIGNMENTS.md](TASK_ASSIGNMENTS.md)**.  
> 📖 Hướng dẫn phối hợp nhóm qua Git & quy trình giải quyết xung đột (Conflict resolution): **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)**.

---

## 📌 Các lưu ý quan trọng khi phát triển (Troubleshooting)

- **Tránh lỗi .NET khi mở dự án trên VS Code**: Nếu bạn đã cài đặt extension **C# Dev Kit**, extension này có thể quét nhầm các file solution C++ do Flutter Windows build sinh ra. Dự án đã bổ sung cấu hình trong `.vscode/settings.json` để ngăn ngừa tình trạng này. Bạn cũng có thể nhấn chuột phải vào extension *C# Dev Kit* và chọn *Disable (Workspace)*.
- **CORS & Authentication**: Backend đã cấu hình sẵn Spring Security và CORS Filter, cho phép Web Frontend gửi request kèm JWT token mà không bị block.
- **Tự động đồng bộ Schema**: Thuộc tính `spring.jpa.hibernate.ddl-auto=update` được bật để tự động đồng bộ thêm cột hoặc bảng mới khi Entity trong Java thay đổi.

