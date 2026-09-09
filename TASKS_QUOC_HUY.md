# 📋 BẢNG PHÂN CÔNG NHIỆM VỤ CÁ NHÂN: PHẠM QUỐC HUY

> **Thành viên**: **Phạm Quốc Huy**  
> **Mã số sinh viên (MSSV)**: **24110226**  
> **Vai trò trong nhóm**: **Main Fullstack Developer** *(Lập trình viên chính tham gia toàn bộ vòng đời SDLC)*  
> **Mảng Kỹ thuật Phụ trách Đầu mối (Lead)**: **Lead BA & Báo cáo Học thuật (Requirements & Documentation Lead)**  
> **Dự án**: Nền tảng Tìm bạn cùng thuê trọ và Ghép bạn trọ theo tiêu chí (Roommate Matching Hub)  
> **Thời gian thực hiện**: **09/09/2026 – 23/09/2026** (14 ngày)  
> **HẠN CHÓT BÀN GIAO TOÀN DIỆN (HARD DEADLINE)**: ⏰ **18:00 Thứ Tư, ngày 23/09/2026**

---

## 🎯 1. TỔNG QUAN TRÁCH NHIỆM CHÍNH (KEY RESPONSIBILITIES)

1. **Lập trình Backend (Spring Boot 3)**:
   - Chịu trách nhiệm trực tiếp viết mã nguồn cho **Module Khảo sát Tiêu chí 5 chiều (`UserPreference`)** và **Module Quản trị Admin (`AdminController`, `AdminService`)**.
2. **Lập trình Frontend (Flutter)**:
   - Chịu trách nhiệm trực tiếp xây dựng giao diện và logic cho **Form Khảo sát Tiêu chí Đa bước (Survey Screen)** và **Trang Thông tin Cá nhân & Cài đặt (Profile Screen)**.
3. **Phụ trách Đầu mối BA & Tài liệu Học thuật (Lead BA & Docs)**:
   - Chủ trì xây dựng và cập nhật tài liệu đặc tả 54 yêu cầu chức năng ([`Nhom13_Mohinhhoayeucau.docx`](docs/Nhom13_Mohinhhoayeucau.docx)).
   - Thiết kế hệ thống 6 Lược đồ Use Case, Sequence Diagram luồng Khảo sát, biên soạn Slide thuyết trình cuối kỳ.
4. **Quy trình Git cá nhân**:
   - Nhánh làm việc chính: `feature/user-preference`, `feature/admin-management`, `docs/system-design`.
   - Luôn `git checkout master` và `git pull origin master` trước khi tạo nhánh mới.
   - Tuân thủ hướng dẫn tại [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md).

---

## 📅 2. LỘ TRÌNH TIẾN ĐỘ & CỘT MỐC DEADLINE CÁ NHÂN

| Giai đoạn | Hạng mục công việc chính | Thời gian | Hạn chót (Deadline) | Trạng thái |
| :---: | :--- | :---: | :---: | :---: |
| **Giai đoạn 1** | Khảo sát yêu cầu, biên soạn 54 FRs, tài liệu Word đặc tả | 09/09 - 10/09 | **23:59 10/09/2026** | ✅ **ĐÃ HOÀN THÀNH** |
| **Giai đoạn 2** | Vẽ 6 sơ đồ Use Case, thiết kế giao diện Form khảo sát & Admin | 11/09 - 12/09 | **23:59 12/09/2026** | ⏳ **ĐANG LÀM** |
| **Giai đoạn 3** | Lập trình Backend APIs: `UserPreference` & `Admin` | 13/09 - 15/09 | **23:59 15/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 4** | Lập trình Frontend Flutter: Màn hình Survey 5 chiều & Profile | 16/09 - 19/09 | **23:59 19/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 5** | Tích hợp E2E Survey, viết tài liệu kiểm thử UAT & Slide báo cáo | 20/09 - 22/09 | **23:59 22/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 6** | Tổng duyệt kịch bản Demo, đóng gói báo cáo hoàn thiện | 23/09/2026 | ⏰ **18:00 23/09/2026** | 🎯 **GỜ BÀN GIAO** |

---

## 📝 3. CHI TIẾT TỪNG NHIỆM VỤ VÀ DEADLINE CỤ THỂ

### GIAI ĐOẠN 1: KHẢO SÁT & MÔ HÌNH HÓA YÊU CẦU (09/09 – 10/09/2026)
- [x] **Task QH-1.1**: Nghiên cứu hiện trạng và đối chiếu 4 mẫu tài liệu của Giảng viên.  
  - *Hạn chót*: `18:00 09/09/2026` | *Trạng thái*: ✅ **Xong**
- [x] **Task QH-1.2**: Xây dựng danh sách 54 Yêu cầu chức năng (FRs), 5 biểu mẫu nghiệp vụ, 7 Use Case đặc tả chi tiết.  
  - *Hạn chót*: `22:00 09/09/2026` | *Trạng thái*: ✅ **Xong**  
  - *Sản phẩm*: [`docs/Nhom13_Mohinhhoayeucau.docx`](docs/Nhom13_Mohinhhoayeucau.docx)
- [x] **Task QH-1.3**: Phối hợp cùng Tiến Đạt kiểm tra tính khớp nối giữa 54 FRs và cấu trúc bảng CSDL `database/01_schema.sql`.  
  - *Hạn chót*: `12:00 10/09/2026` | *Trạng thái*: ✅ **Xong**

---

### GIAI ĐOẠN 2: THIẾT KẾ HỆ THỐNG & ĐẶC TẢ CHI TIẾT (11/09 – 12/09/2026)
*Nhánh Git đề xuất: `docs/system-design`*

- [ ] **Task QH-2.1: Vẽ 6 Lược đồ Use Case phân hệ**
  - *Hạn chót*: ⏰ **17:00 Thứ Sáu, 11/09/2026**
  - *Mô tả*: Vẽ 6 sơ đồ Use Case bằng công cụ StarUML / Draw.io / PlantUML gồm:
    1. Phân hệ Xác thực & Người dùng (Actor: Sinh viên/Người dùng).
    2. Phân hệ Khảo sát & Quản lý Tiêu chí cá nhân (Actor: Sinh viên).
    3. Phân hệ Tìm kiếm & Lọc bạn trọ (Actor: Sinh viên).
    4. Phân hệ Ghép đôi & Lời mời ghép trọ (Actor: Sinh viên).
    5. Phân hệ Đăng tin phòng & Lịch hẹn xem trọ (Actor: Sinh viên, Chủ phòng).
    6. Phân hệ Quản trị hệ thống & Kiểm duyệt (Actor: Admin).
  - *Đầu ra*: Xuất file ảnh PNG/SVG chất lượng cao vào thư mục `docs/diagrams/use_cases/`.
  - *Bàn giao*: Gửi file sơ đồ cho Quang Huy và Tiến Đạt để đối chiếu Class Diagram.

- [ ] **Task QH-2.2: Thiết kế Sequence Diagram luồng Khảo sát Tiêu chí & Quản trị Admin**
  - *Hạn chót*: ⏰ **12:00 Thứ Bảy, 12/09/2026**
  - *Mô tả*: Vẽ sơ đồ tuần tự thể hiện tương tác giữa Mobile Client -> Spring Controller -> Service -> Repository -> MySQL:
    1. Luồng Người dùng cập nhật bảng khảo sát 5 chiều (`UserPreference`).
    2. Luồng Admin khóa tài khoản vi phạm hoặc duyệt bài đăng phòng trọ.
  - *Đầu ra*: File thiết kế tuần tự lưu tại `docs/diagrams/sequences/`.

- [ ] **Task QH-2.3: Viết tài liệu đặc tả User Stories & Bộ tiêu chí khảo sát 5 chiều**
  - *Hạn chót*: ⏰ **23:59 Thứ Bảy, 12/09/2026**
  - *Mô tả*: Đặc tả rõ thang đo, trọng số và giải thuật mapping cho 5 nhóm tiêu chí:
    1. Ngân sách thuê phòng (Min - Max giá, kỳ hạn thanh toán).
    2. Khu vực địa lý (Quận/Huyện, bán kính km quanh trường học/chỗ làm).
    3. Lối sống & Sinh hoạt (Giờ giấc ngủ nghỉ, nấu ăn, tụ tập bạn bè).
    4. Thói quen cá nhân (Hút thuốc, nuôi thú cưng, giữ vệ sinh, ngăn nắp).
    5. Tính cách & Sở thích (Mức độ hướng nội/hướng ngoại, sở thích chung).
  - *Đầu ra*: Markdown spec bàn giao cho Quang Huy (code Matching Engine) và Tiến Đạt (cập nhật DB).

---

### GIAI ĐOẠN 3: LẬP TRÌNH BACKEND SPRING BOOT 3 (13/09 – 15/09/2026)
*Nhánh Git đề xuất: `feature/user-preference` & `feature/admin-backend`*

- [ ] **Task QH-3.1: Lập trình Backend Module `UserPreference`**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 14/09/2026**
  - *Mô tả*:
    - Xây dựng Entity: `UserPreference.java` ánh xạ bảng `user_preferences`.
    - Viết DTOs: `PreferenceRequest.java`, `PreferenceResponse.java`.
    - Viết Service & Repository: Xử lý logic lưu mới và cập nhật khảo sát theo `userId`.
    - Xây dựng REST API Controller `UserPreferenceController.java`:
      - `POST /api/v1/preferences`: Lưu kết quả khảo sát lần đầu.
      - `PUT /api/v1/preferences`: Cập nhật tiêu chí hiện tại.
      - `GET /api/v1/preferences/me`: Lấy thông tin tiêu chí của user đang đăng nhập.
      - `GET /api/v1/preferences/user/{userId}`: Xem tiêu chí công khai của ứng viên.
  - *Đầu ra*: Code sạch, chạy pass trên Postman, đã push lên Git.
  - *Bàn giao*: Cung cấp API endpoint cho Quang Huy để tích hợp vào Matching Engine.

- [ ] **Task QH-3.2: Lập trình Backend Module Quản trị `Admin`**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 15/09/2026**
  - *Mô tả*:
    - Viết Controller `AdminController.java` phân quyền `@PreAuthorize("hasRole('ADMIN')")`:
      - `GET /api/v1/admin/users`: Danh sách tất cả người dùng kèm trạng thái `ACTIVE`/`BLOCKED`.
      - `PUT /api/v1/admin/users/{id}/status`: Khóa hoặc kích hoạt lại tài khoản.
      - `GET /api/v1/admin/reports`: Danh sách các tố cáo vi phạm từ người dùng.
      - `PUT /api/v1/admin/posts/{id}/approve`: Duyệt hoặc từ chối bài đăng phòng trọ.
  - *Đầu ra*: Code Backend quản trị hoàn chỉnh, có xử lý lỗi và bắt exception rõ ràng.

- [ ] **Task QH-3.3: Viết Unit Test cho Preference & Admin Service**
  - *Hạn chót*: ⏰ **23:59 Thứ Hai, 15/09/2026**
  - *Mô tả*: Sử dụng JUnit 5 & Mockito viết ít nhất 6 test cases:
    - Test lưu tiêu chí hợp lệ và test validate dữ liệu âm/sai định dạng.
    - Test kiểm tra quyền Admin khi gọi API quản trị.
  - *Đầu ra*: Lệnh `mvn test` chạy xanh 100% không có lỗi.

---

### GIAI ĐOẠN 4: LẬP TRÌNH FRONTEND FLUTTER CLIENT (16/09 – 19/09/2026)
*Nhánh Git đề xuất: `feature/survey-profile-ui`*

- [ ] **Task QH-4.1: Xây dựng Giao diện Form Khảo sát Tiêu chí 5 chiều (Survey Screen)**
  - *Hạn chót*: ⏰ **23:59 Thứ Tư, 17/09/2026**
  - *Mô tả*:
    - Tạo màn hình `survey_screen.dart` dạng Multi-step Wizard hoặc Tab Page:
      - Bước 1: Chọn tầm giá (RangeSlider trực quan) & Quận/Vị trí mong muốn.
      - Bước 2: Thói quen sinh hoạt (Cú đêm / Dậy sớm, Nấu ăn ở nhà / Ăn ngoài).
      - Bước 3: Thói quen lối sống (Hút thuốc: Có/Không, Thú cưng: Thích/Dị ứng, Độ ngăn nắp: 1-5 sao).
      - Bước 4: Tính cách & Sở thích (FilterChips chọn tag: Đọc sách, Thể thao, Chơi game, Yên tĩnh...).
      - Bước 5: Màn hình tóm tắt & Nút "Lưu & Bắt đầu tìm bạn trọ".
    - Validate dữ liệu đầu vào không để trống các mục bắt buộc.
  - *Đầu ra*: Giao diện hiện đại, mượt mà, hỗ trợ cả Mobile và Web.

- [ ] **Task QH-4.2: Xây dựng Màn hình Hồ sơ Cá nhân (Profile Screen)**
  - *Hạn chót*: ⏰ **23:59 Thứ Năm, 18/09/2026**
  - *Mô tả*:
    - File `profile_screen.dart`: Hiển thị Avatar, Tên, Trường học, Giới tính, Giới thiệu bản thân.
    - Nút "Chỉnh sửa tiêu chí ghép trọ": Cho phép mở lại form khảo sát để cập nhật.
    - Hiển thị Huy hiệu Xác thực sinh viên (Student Verified Badge).
    - Màn hình Đổi mật khẩu & Cài đặt thông báo.
  - *Đầu ra*: Màn hình Profile hoạt động trơn tru với dữ liệu Mock và State.

- [ ] **Task QH-4.3: Xây dựng Giao diện Quản trị viên (Admin Dashboard)**
  - *Hạn chót*: ⏰ **23:59 Thứ Sáu, 19/09/2026**
  - *Mô tả*:
    - Xây dựng màn hình `admin_dashboard_screen.dart`:
      - Thống kê tổng quan: Số người dùng, Số bài đăng, Số cặp đã ghép.
      - Bảng danh sách tài khoản: Nút Khóa / Mở khóa tài khoản.
      - Danh sách bài đăng chờ duyệt: Nút Duyệt / Từ chối.
  - *Đầu ra*: Giao diện Admin quản trị trực quan.

---

### GIAI ĐOẠN 5: TÍCH HỢP E2E, KIỂM THỬ VÀ BÁO CÁO (20/09 – 22/09/2026)
*Nhánh Git đề xuất: `integration/survey-profile` & `docs/final-report`*

- [ ] **Task QH-5.1: Tích hợp Frontend Survey & Profile với Backend API**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 20/09/2026**
  - *Mô tả*:
    - Kết nối màn hình `survey_screen.dart` gọi API `POST /api/v1/preferences` lưu vào MySQL thật.
    - Hiển thị Toast thông báo thành công và chuyển hướng thông minh đến trang Khám phá bạn trọ.
  - *Đầu ra*: Luồng khảo sát hoạt động trọn vẹn End-to-End từ giao diện xuống cơ sở dữ liệu.

- [ ] **Task QH-5.2: Viết Kịch bản Kiểm thử Chấp nhận Người dùng (UAT Test Cases)**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 21/09/2026**
  - *Mô tả*:
    - Soạn thảo 15 kịch bản UAT tương ứng với các FRs về khảo sát tiêu chí và quản trị tài khoản.
    - Chạy thử nghiệm thực tế và ghi nhận kết quả Pass/Fail.
  - *Đầu ra*: File biên bản kiểm thử UAT gửi cho Lead QA Tiến Đạt.

- [ ] **Task QH-5.3: Hoàn thiện Slide Báo cáo & Bổ sung Tài liệu Tổng kết Đồ án**
  - *Hạn chót*: ⏰ **23:59 Thứ Ba, 22/09/2026**
  - *Mô tả*:
    - Thiết kế bộ Slide thuyết trình (PowerPoint / Canva) 15-20 trang gồm: Đặt vấn đề, Giải pháp, Kiến trúc hệ thống, Demo kết quả và Bài học kinh nghiệm.
    - Rà soát toàn bộ file Word [`Nhom13_Mohinhhoayeucau.docx`](docs/Nhom13_Mohinhhoayeucau.docx) đảm bảo định dạng học thuật chuẩn chỉ.
  - *Đầu ra*: File Slide `.pptx` / PDF và tài liệu báo cáo hoàn chỉnh.

---

### GIAI ĐOẠN 6: TỔNG DUYỆT DEMO & BÀN GIAO TOÀN DIỆN (23/09/2026)
*Hạn chót toàn dự án: ⏰ **18:00 Thứ Tư, 23/09/2026***

- [ ] **Task QH-6.1: Tổng duyệt Kịch bản Demo luồng Khảo sát & Admin**
  - *Hạn chót*: ⏰ **12:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Cùng Quang Huy và Tiến Đạt chạy thử kịch bản demo: Tạo tài khoản mới -> Làm bài khảo sát tiêu chí -> Xem gợi ý bạn trọ -> Admin kiểm duyệt.
- [ ] **Task QH-6.2: Bàn giao toàn bộ tài liệu báo cáo và slide chính thức**
  - *Hạn chót*: ⏰ **18:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Đóng gói toàn bộ file báo cáo Word, PDF, sơ đồ và Slide vào thư mục `docs/` và bàn giao cho PM Leader.

---

## 🔍 4. BẢNG TỰ KIỂM TRA CHẤT LƯỢNG (SELF-CHECKLIST TRƯỚC KHI TẠO PR)

Trước khi tạo Pull Request vào nhánh `master`, Quốc Huy tự kiểm tra các tiêu chí sau:
- [ ] Code tuân thủ quy tắc đặt tên Java / Dart (CamelCase).
- [ ] Không có warning hoặc lỗi cú pháp biên dịch.
- [ ] Các API Backend đã được test cẩn thận trên Postman.
- [ ] Giao diện Flutter hiển thị đúng trên cả kích thước màn hình điện thoại và web.
- [ ] Đã chạy `git pull origin master` để giải quyết conflict trước khi đẩy code.
