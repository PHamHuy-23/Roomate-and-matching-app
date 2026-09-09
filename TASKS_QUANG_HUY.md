# 📋 BẢNG PHÂN CÔNG NHIỆM VỤ CÁ NHÂN: TRẦN QUANG HUY

> **Thành viên**: **Trần Quang Huy**  
> **Mã số sinh viên (MSSV)**: **24110228**  
> **Vai trò trong nhóm**: **Main Fullstack Developer** *(Lập trình viên chính tham gia toàn bộ vòng đời SDLC)*  
> **Mảng Kỹ thuật Phụ trách Đầu mối (Lead)**: **Lead Kiến trúc Kỹ thuật & Prototype (Technical & Architecture Lead)**  
> **Dự án**: Nền tảng Tìm bạn cùng thuê trọ và Ghép bạn trọ theo tiêu chí (Roommate Matching Hub)  
> **Thời gian thực hiện**: **09/09/2026 – 23/09/2026** (14 ngày)  
> **HẠN CHÓT BÀN GIAO TOÀN DIỆN (HARD DEADLINE)**: ⏰ **18:00 Thứ Tư, ngày 23/09/2026**

---

## 🎯 1. TỔNG QUAN TRÁCH NHIỆM CHÍNH (KEY RESPONSIBILITIES)

1. **Lập trình Backend (Spring Boot 3)**:
   - Chịu trách nhiệm trực tiếp viết mã nguồn cho **Module Xác thực & Bảo mật (`AuthController`, `JwtTokenProvider`, Spring Security)**.
   - Chịu trách nhiệm trực tiếp xây dựng **Lõi Thuật toán Gợi ý Ghép đôi (`MatchingEngineService`)** tính toán % tương thích đa tiêu chí có trọng số.
2. **Lập trình Frontend (Flutter)**:
   - Chịu trách nhiệm thiết lập khung kiến trúc ứng dụng (State Management, HTTP Interceptor, Routing).
   - Chịu trách nhiệm trực tiếp xây dựng giao diện và logic cho **Màn hình Đăng nhập / Đăng ký (`login_screen.dart`, `register_screen.dart`)** và **Màn hình Khám phá & Gợi ý bạn trọ (`discovery_screen.dart`)**.
3. **Phụ trách Đầu mối Kiến trúc Kỹ thuật & DevOps (Lead Technical)**:
   - Chủ trì chuẩn hóa tài liệu API Contract (Swagger / OpenAPI).
   - Thiết kế Sequence Diagram luồng Đăng nhập JWT và luồng Thuật toán Matching.
   - Quản lý build và đóng gói bản phát hành thử nghiệm (APK Android / Flutter Web Release).
4. **Quy trình Git cá nhân**:
   - Nhánh làm việc chính: `feature/auth-jwt`, `feature/matching-engine`, `feature/flutter-discovery`.
   - Luôn `git checkout master` và `git pull origin master` trước khi tạo nhánh mới.
   - Tuân thủ hướng dẫn tại [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md).

---

## 📅 2. LỘ TRÌNH TIẾN ĐỘ & CỘT MỐC DEADLINE CÁ NHÂN

| Giai đoạn | Hạng mục công việc chính | Thời gian | Hạn chót (Deadline) | Trạng thái |
| :---: | :--- | :---: | :---: | :---: |
| **Giai đoạn 1** | Khởi tạo khung Prototype Backend & Frontend, fix lỗi .NET | 09/09 - 10/09 | **23:59 10/09/2026** | ✅ **ĐÃ HOÀN THÀNH** |
| **Giai đoạn 2** | Thiết kế Sequence Diagram Auth & Matching, chuẩn hóa API Spec | 11/09 - 12/09 | **23:59 12/09/2026** | ⏳ **ĐANG LÀM** |
| **Giai đoạn 3** | Lập trình Backend APIs: Auth/JWT & Lõi Matching Engine | 13/09 - 15/09 | **23:59 15/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 4** | Lập trình Frontend Flutter: Màn hình Auth & Khám phá Match % | 16/09 - 19/09 | **23:59 19/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 5** | Tích hợp E2E Auth & Matching, tối ưu hiệu năng, giải quyết conflict | 20/09 - 22/09 | **23:59 22/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 6** | Build bản cài đặt APK/Web Release, hỗ trợ diễn tập Demo | 23/09/2026 | ⏰ **18:00 23/09/2026** | 🎯 **GỜ BÀN GIAO** |

---

## 📝 3. CHI TIẾT TỪNG NHIỆM VỤ VÀ DEADLINE CỤ THỂ

### GIAI ĐOẠN 1: THIẾT LẬP NỀN TẢNG PROTOTYPE (09/09 – 10/09/2026)
- [x] **Task QH2-1.1**: Khởi tạo khung Backend Spring Boot 3 (`backend/`) kèm Maven wrapper, cấu hình kết nối MySQL và CORS.  
  - *Hạn chót*: `18:00 09/09/2026` | *Trạng thái*: ✅ **Xong**
- [x] **Task QH2-1.2**: Khởi tạo khung ứng dụng Flutter (`frontend/`), cấu hình routing cơ bản và giao diện khung.  
  - *Hạn chót*: `21:00 09/09/2026` | *Trạng thái*: ✅ **Xong**
- [x] **Task QH2-1.3**: Xử lý triệt để xung đột bộ đọc giải pháp .NET trong VS Code qua cấu hình `.vscode/settings.json`.  
  - *Hạn chót*: `12:00 10/09/2026` | *Trạng thái*: ✅ **Xong**

---

### GIAI ĐOẠN 2: THIẾT KẾ KIẾN TRÚC & API CONTRACTS (11/09 – 12/09/2026)
*Nhánh Git đề xuất: `docs/technical-architecture`*

- [ ] **Task QH2-2.1: Thiết kế Sequence Diagram luồng Xác thực JWT & Thuật toán Matching**
  - *Hạn chót*: ⏰ **18:00 Thứ Sáu, 11/09/2026**
  - *Mô tả*: Vẽ 2 sơ đồ tuần tự chi tiết bằng Draw.io / PlantUML:
    1. **Luồng Xác thực JWT**: Client gửi email/password -> `AuthController` -> `AuthenticationManager` -> `JwtTokenProvider` tạo Access Token & Refresh Token -> Trả về Client lưu SecureStorage -> Gắn header `Authorization: Bearer <token>` vào các request tiếp theo.
    2. **Luồng Thuật toán Matching**: Client yêu cầu gợi ý -> `MatchingEngineService` truy vấn danh sách ứng viên từ DB -> Tính khoảng cách Euclidean/Cosine theo 5 trọng số tiêu chí (Ngân sách, Địa điểm, Lối sống, Thói quen, Sở thích) -> Sắp xếp giảm dần theo % tương thích -> Trả về danh sách ứng viên kèm điểm chi tiết từng phần.
  - *Đầu ra*: File sơ đồ PNG/SVG lưu tại `docs/diagrams/sequences/`.
  - *Bàn giao*: Gửi sơ đồ cho Quốc Huy tích hợp vào báo cáo học thuật.

- [ ] **Task QH2-2.2: Đặc tả chuẩn REST API Contracts (OpenAPI / Swagger Specs)**
  - *Hạn chót*: ⏰ **18:00 Thứ Bảy, 12/09/2026**
  - *Mô tả*:
    - Xây dựng file đặc tả JSON/YAML chuẩn OpenAPI 3.0 cho toàn bộ hệ thống API.
    - Định nghĩa cấu trúc chuẩn cho Response:
      ```json
      {
        "status": 200,
        "message": "Success",
        "data": { ... }
      }
      ```
    - Quy định mã lỗi HTTP chuẩn (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 500 Server Error).
  - *Đầu ra*: Tài liệu API specification bàn giao cho cả 3 thành viên đối chiếu khi code Backend và Flutter.

- [ ] **Task QH2-2.3: Chuẩn hóa cấu trúc thư mục Flutter & Cấu hình Network Client**
  - *Hạn chót*: ⏰ **23:59 Thứ Bảy, 12/09/2026**
  - *Mô tả*:
    - Tổ chức cấu trúc thư mục `frontend/lib/`:
      - `core/` (constants, themes, routes, utils)
      - `models/` (user, preference, post, match_request)
      - `services/` (api_service, auth_service, storage_service)
      - `screens/` (auth, survey, discovery, room, profile, admin)
      - `widgets/` (custom_button, candidate_card, match_badge)
    - Cài đặt cấu hình tự động đính kèm `Bearer Token` vào HTTP Header khi gọi API.
  - *Đầu ra*: Bộ khung Flutter sạch sẵn sàng cho giai đoạn code màn hình.

---

### GIAI ĐOẠN 3: LẬP TRÌNH BACKEND SPRING BOOT 3 (13/09 – 15/09/2026)
*Nhánh Git đề xuất: `feature/auth-jwt` & `feature/matching-engine`*

- [ ] **Task QH2-3.1: Lập trình Module Xác thực & Phân quyền Bảo mật (Auth & Security)**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 14/09/2026**
  - *Mô tả*:
    - Tích hợp Spring Security 6 & JJWT (`io.jsonwebtoken`).
    - Viết `JwtAuthenticationFilter`, `JwtTokenProvider`, `CustomUserDetailsService`.
    - Viết `AuthController.java`:
      - `POST /api/v1/auth/register`: Đăng ký tài khoản mới kèm mã hóa BCrypt password.
      - `POST /api/v1/auth/login`: Xác thực và cấp cặp Access Token (hạn 24h) + Refresh Token (hạn 7 ngày).
      - `POST /api/v1/auth/refresh`: Cấp lại Access Token mới khi hết hạn.
      - `GET /api/v1/auth/me`: Lấy thông tin user hiện tại từ token.
    - Phân quyền endpoint theo Role: `ROLE_USER` và `ROLE_ADMIN`.
  - *Đầu ra*: Chạy thử nghiệm thành công 100% các case trên Postman.
  - *Bàn giao*: Cung cấp cơ chế JWT cho Tiến Đạt và Quốc Huy để bảo vệ các endpoints khác.

- [ ] **Task QH2-3.2: Lập trình Lõi Thuật toán Matching (`MatchingEngineService`)**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 15/09/2026**
  - *Mô tả*:
    - Viết Service `MatchingEngineService.java` áp dụng công thức tính điểm tương thích có trọng số:
      $$\text{Score} = w_1 \cdot S_{\text{budget}} + w_2 \cdot S_{\text{location}} + w_3 \cdot S_{\text{lifestyle}} + w_4 \cdot S_{\text{habits}} + w_5 \cdot S_{\text{personality}}$$
      *(Trọng số đề xuất: Ngân sách 30%, Vị trí 25%, Lối sống 20%, Thói quen 15%, Sở thích 10%)*.
    - Viết REST API Controller `MatchingController.java`:
      - `GET /api/v1/matching/recommendations`: Trả về danh sách ứng viên kèm % Match giảm dần.
      - `GET /api/v1/matching/compare/{targetUserId}`: So sánh chi tiết độ hợp giữa user hiện tại và một ứng viên cụ thể.
  - *Đầu ra*: API tính toán nhanh, trả về kết quả chính xác, có benchmark thời gian phản hồi.

- [ ] **Task QH2-3.3: Viết Unit Tests cho Auth & Thuật toán Matching Engine**
  - *Hạn chót*: ⏰ **23:59 Thứ Hai, 15/09/2026**
  - *Mô tả*: Viết JUnit 5 test cases:
    - Test mã hóa và kiểm tra password BCrypt.
    - Test tạo và parse JWT token hợp lệ / quá hạn.
    - Test thuật toán Matching: Hai hồ sơ giống hệt nhau phải đạt 100%, hồ sơ đối lập đạt điểm thấp.
  - *Đầu ra*: Chạy `mvn test` pass toàn bộ.

---

### GIAI ĐOẠN 4: LẬP TRÌNH FRONTEND FLUTTER CLIENT (16/09 – 19/09/2026)
*Nhánh Git đề xuất: `feature/auth-discovery-ui`*

- [ ] **Task QH2-4.1: Xây dựng Giao diện Đăng ký, Đăng nhập & Xác thực**
  - *Hạn chót*: ⏰ **23:59 Thứ Tư, 17/09/2026**
  - *Mô tả*:
    - Tạo màn hình `login_screen.dart`: Form nhập email/mật khẩu, ghi nhớ đăng nhập, nút Đăng nhập, liên kết Đăng ký.
    - Tạo màn hình `register_screen.dart`: Nhập thông tin họ tên, email sinh viên, số điện thoại, mật khẩu, chọn trường đại học.
    - Lưu JWT Token an toàn bằng `flutter_secure_storage` hoặc `shared_preferences`.
    - Tự động điều hướng: Nếu đã đăng nhập thì vào trang chính, nếu chưa thì hiển thị màn hình Auth.
  - *Đầu ra*: Màn hình Auth đẹp mắt, validate lỗi tức thì (form validation).

- [ ] **Task QH2-4.2: Xây dựng Giao diện Khám phá & Gợi ý bạn trọ (Discovery Feed)**
  - *Hạn chót*: ⏰ **23:59 Thứ Năm, 18/09/2026**
  - *Mô tả*:
    - Tạo màn hình `discovery_screen.dart`:
      - Danh sách ứng viên bạn trọ dạng Card trực quan.
      - Huy hiệu phần trăm tương thích nổi bật (VD: `Match 92%` màu xanh lá, `Match 75%` màu vàng).
      - Hiển thị tóm tắt: Tên, Tuổi, Trường, Thói quen chính, Khoảng ngân sách.
      - Nút "Gửi lời mời ghép trọ" và Nút "Xem hồ sơ chi tiết".
    - Bộ lọc nhanh trên thanh công cụ: Lọc theo % tối thiểu, lọc theo quận, lọc theo giới tính.
  - *Đầu ra*: Giao diện mượt mà, hỗ trợ kéo để làm mới (Pull-to-refresh).

- [ ] **Task QH2-4.3: Xây dựng Màn hình Chi tiết Ứng viên & So sánh Tiêu chí**
  - *Hạn chót*: ⏰ **23:59 Thứ Sáu, 19/09/2026**
  - *Mô tả*:
    - Tạo `candidate_detail_screen.dart`:
      - Biểu đồ mạng nhện (Radar Chart) hoặc Progress Bar so sánh 5 tiêu chí giữa 2 người.
      - Chỉ ra điểm hợp nhau (Match Highlights) và điểm khác biệt cần lưu ý.
  - *Đầu ra*: Giao diện so sánh trực quan, sinh động.

---

### GIAI ĐOẠN 5: TÍCH HỢP E2E, TỐI ƯU HIỆU NĂNG & QA (20/09 – 22/09/2026)
*Nhánh Git đề xuất: `integration/auth-matching`*

- [ ] **Task QH2-5.1: Tích hợp Toàn diện Luồng Auth & Matching Feed**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 20/09/2026**
  - *Mô tả*: Kết nối Frontend gọi Backend thật, kiểm tra luồng cấp và làm mới token khi hết hạn tự động qua Interceptor.
- [ ] **Task QH2-5.2: Tối ưu Hiệu năng, Xử lý Xung đột Code (Git Conflict) & Review**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 21/09/2026**
  - *Mô tả*:
    - Hỗ trợ các bạn trong nhóm giải quyết các xung đột merge trên Git.
    - Tối ưu kích thước bundle và thời gian render màn hình Flutter.
- [ ] **Task QH2-5.3: Chuẩn bị Cấu hình Triển khai & Kiểm thử Multi-platform**
  - *Hạn chót*: ⏰ **23:59 Thứ Ba, 22/09/2026**
  - *Mô tả*: Chạy thử nghiệm hệ thống trên cả 3 môi trường: Trình duyệt Chrome/Edge, Máy ảo Android Emulator và Windows Desktop.

---

### GIAI ĐOẠN 6: BUILD PHÁT HÀNH & HỖ TRỢ DEMO (23/09/2026)
*Hạn chót toàn dự án: ⏰ **18:00 Thứ Tư, 23/09/2026***

- [ ] **Task QH2-6.1: Build file cài đặt phát hành chính thức (Release Build)**
  - *Hạn chót*: ⏰ **14:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Build file APK (`app-release.apk`) và xuất bản Flutter Web thư mục `build/web/`.
- [ ] **Task QH2-6.2: Tham gia tổng duyệt kịch bản Demo hoàn chỉnh trước giờ G**
  - *Hạn chót*: ⏰ **18:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Đảm bảo server Backend và ứng dụng chạy mượt mà, không gặp bất kỳ lỗi crash nào.

---

## 🔍 4. BẢNG TỰ KIỂM TRA CHẤT LƯỢNG (SELF-CHECKLIST TRƯỚC KHI TẠO PR)

Trước khi tạo Pull Request vào nhánh `master`, Quang Huy tự kiểm tra các tiêu chí sau:
- [ ] Token JWT được lưu an toàn, không lộ trong log console.
- [ ] API trả về đúng định dạng chuẩn đã cam kết trong API Spec.
- [ ] Màn hình Flutter không bị lỗi tràn viền (A RenderFlex overflowed).
- [ ] Các tác vụ mạng (HTTP request) đều có vòng quay Loading (`CircularProgressIndicator`) và xử lý lỗi mạng.
- [ ] Đã chạy `git pull origin master` trước khi đẩy mã nguồn.
