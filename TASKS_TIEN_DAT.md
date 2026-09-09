# 📋 BẢNG PHÂN CÔNG NHIỆM VỤ CÁ NHÂN: PHAN TIẾN ĐẠT

> **Thành viên**: **Phan Tiến Đạt**  
> **Mã số sinh viên (MSSV)**: **24110195**  
> **Vai trò trong nhóm**: **Main Fullstack Developer** *(Lập trình viên chính tham gia toàn bộ vòng đời SDLC)*  
> **Mảng Kỹ thuật Phụ trách Đầu mối (Lead)**: **Lead Cơ sở Dữ liệu & Đảm bảo Chất lượng (Database & QA Lead)**  
> **Dự án**: Nền tảng Tìm bạn cùng thuê trọ và Ghép bạn trọ theo tiêu chí (Roommate Matching Hub)  
> **Thời gian thực hiện**: **09/09/2026 – 23/09/2026** (14 ngày)  
> **HẠN CHÓT BÀN GIAO TOÀN DIỆN (HARD DEADLINE)**: ⏰ **18:00 Thứ Tư, ngày 23/09/2026**

---

## 🎯 1. TỔNG QUAN TRÁCH NHIỆM CHÍNH (KEY RESPONSIBILITIES)

1. **Lập trình Backend (Spring Boot 3)**:
   - Chịu trách nhiệm trực tiếp viết mã nguồn cho **Module Bài đăng Phòng trọ (`RoomPostController`, `RoomPostService`)** (CRUD, tìm kiếm theo quận/giá, quản lý trạng thái bài đăng).
   - Chịu trách nhiệm trực tiếp viết mã nguồn cho **Module Yêu cầu Ghép đôi & Lịch hẹn Xem trọ (`MatchRequestController`, `AppointmentController`)** (Quy trình Double Opt-in, cấp quyền xem số điện thoại, đặt lịch xem phòng trực tiếp).
2. **Lập trình Frontend (Flutter)**:
   - Chịu trách nhiệm trực tiếp xây dựng giao diện và logic cho **Bảng tin Danh sách Phòng trọ (`room_feed_screen.dart`)**, **Chi tiết Phòng trọ (`room_detail_screen.dart`)**, **Form Đăng tin Phòng (`create_room_post_screen.dart`)** và **Màn hình Quản lý Lịch hẹn & Lời mời (`appointment_screen.dart`)**.
3. **Phụ trách Đầu mối CSDL & QA (Lead Database & QA)**:
   - Chủ trì thiết kế sơ đồ CSDL quan hệ (ERD), viết các script DDL mở rộng (`viewing_appointments`, `contact_permissions`, `reports`).
   - Xây dựng Kế hoạch Kiểm thử (Test Plan), Bảng ma trận kiểm thử (Test Matrix) cho 54 yêu cầu chức năng, lập Bug Tracker giám sát lỗi hệ thống.
   - Chuẩn bị bộ dữ liệu mẫu Demo (Clean Seed Data) sinh động, chân thực cho buổi báo cáo.
4. **Quy trình Git cá nhân**:
   - Nhánh làm việc chính: `feature/database-expansion`, `feature/room-post-backend`, `feature/appointment-ui`.
   - Luôn `git checkout master` và `git pull origin master` trước khi tạo nhánh mới.
   - Tuân thủ hướng dẫn tại [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md).

---

## 📅 2. LỘ TRÌNH TIẾN ĐỘ & CỘT MỐC DEADLINE CÁ NHÂN

| Giai đoạn | Hạng mục công việc chính | Thời gian | Hạn chót (Deadline) | Trạng thái |
| :---: | :--- | :---: | :---: | :---: |
| **Giai đoạn 1** | Chuẩn hóa CSDL MySQL: DDL `01_schema.sql` & DML `02_seed_data.sql` | 09/09 - 10/09 | **23:59 10/09/2026** | ✅ **ĐÃ HOÀN THÀNH** |
| **Giai đoạn 2** | Bổ sung bảng CSDL mở rộng, vẽ Class Diagram, lập Test Plan | 11/09 - 12/09 | **23:59 12/09/2026** | ⏳ **ĐANG LÀM** |
| **Giai đoạn 3** | Lập trình Backend APIs: `RoomPost` & `MatchRequest / Appointments` | 13/09 - 15/09 | **23:59 15/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 4** | Lập trình Frontend Flutter: Màn hình Room Feed, Đăng tin, Lịch hẹn | 16/09 - 19/09 | **23:59 19/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 5** | Tích hợp E2E Room & Appointment, chạy kiểm thử tự động, Bug Tracker | 20/09 - 22/09 | **23:59 22/09/2026** | ⏳ Hàng đợi |
| **Giai đoạn 6** | Nạp Seed Data sạch, kiểm tra chất lượng tổng thể trước nghiệm thu | 23/09/2026 | ⏰ **18:00 23/09/2026** | 🎯 **GỜ BÀN GIAO** |

---

## 📝 3. CHI TIẾT TỪNG NHIỆM VỤ VÀ DEADLINE CỤ THỂ

### GIAI ĐOẠN 1: THIẾT KẾ CƠ SỞ DỮ LIỆU CHUẨN (09/09 – 10/09/2026)
- [x] **Task TD-1.1**: Chuẩn hóa DDL `database/01_schema.sql` (bảng `users`, `user_preferences`, `room_posts`, `match_requests`).  
  - *Hạn chót*: `18:00 09/09/2026` | *Trạng thái*: ✅ **Xong**
- [x] **Task TD-1.2**: Xây dựng Seed Data mẫu `database/02_seed_data.sql` và file tổng hợp `database/roommate_hub.sql`.  
  - *Hạn chót*: `21:00 09/09/2026` | *Trạng thái*: ✅ **Xong**
- [x] **Task TD-1.3**: Soạn thảo tài liệu hướng dẫn CSDL chi tiết tại `database/README.md`.  
  - *Hạn chót*: `12:00 10/09/2026` | *Trạng thái*: ✅ **Xong**

---

### GIAI ĐOẠN 2: MỞ RỘNG CSDL & KẾ HOẠCH KIỂM THỬ QA (11/09 – 12/09/2026)
*Nhánh Git đề xuất: `feature/database-expansion` & `docs/qa-testplan`*

- [ ] **Task TD-2.1: Mở rộng CSDL MySQL (Bổ sung 3 bảng mới)**
  - *Hạn chót*: ⏰ **18:00 Thứ Sáu, 11/09/2026**
  - *Mô tả*:
    - Viết script migration bổ sung 3 bảng phục vụ 54 FRs mở rộng:
      1. Bảng `viewing_appointments`: Quản lý lịch hẹn xem phòng trực tiếp (id, requester_id, host_id, post_id, appointment_time, status [PENDING/CONFIRMED/CANCELLED], note).
      2. Bảng `contact_permissions`: Quản lý quyền xem thông tin liên lạc nhạy cảm theo nguyên tắc Double Opt-in (id, user_id, requester_id, is_granted, granted_at).
      3. Bảng `reports`: Quản lý tố cáo vi phạm bài đăng hoặc tài khoản (id, reporter_id, target_id, target_type, reason, status [PENDING/RESOLVED]).
    - Cập nhật cả file `database/01_schema.sql` và `database/roommate_hub.sql`.
  - *Đầu ra*: Script SQL chạy không lỗi, có ràng buộc khóa ngoại rõ ràng.
  - *Bàn giao*: Bàn giao cấu trúc bảng cho Quốc Huy và Quang Huy để ánh xạ Entity Java.

- [ ] **Task TD-2.2: Thiết kế Sơ đồ Lớp thực thể (Class Diagram: Entity, DTO, Repository)**
  - *Hạn chót*: ⏰ **12:00 Thứ Bảy, 12/09/2026**
  - *Mô tả*: Vẽ sơ đồ lớp chi tiết thể hiện quan hệ 1-1, 1-nhiều, nhiều-nhiều giữa các Model trong Backend Spring Boot 3.
  - *Đầu ra*: File ảnh sơ đồ lưu tại `docs/diagrams/classes/`.

- [ ] **Task TD-2.3: Xây dựng Kế hoạch Kiểm thử Toàn diện (QA Test Plan)**
  - *Hạn chót*: ⏰ **23:59 Thứ Bảy, 12/09/2026**
  - *Mô tả*:
    - Lập ma trận kiểm thử (Traceability Test Matrix) bao phủ 54 Yêu cầu chức năng (FRs).
    - Phân chia phạm vi kiểm thử: Kiểm thử Chức năng (Functional), Kiểm thử Bảo mật (Security), Kiểm thử Hiệu năng (Performance).
  - *Đầu ra*: File tài liệu `docs/TEST_PLAN.md`.

---

### GIAI ĐOẠN 3: LẬP TRÌNH BACKEND SPRING BOOT 3 (13/09 – 15/09/2026)
*Nhánh Git đề xuất: `feature/room-post-backend` & `feature/appointment-backend`*

- [ ] **Task TD-3.1: Lập trình Backend Module Bài đăng Phòng trọ (`RoomPost`)**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 14/09/2026**
  - *Mô tả*:
    - Xây dựng Entity: `RoomPost.java` và quan hệ `@ManyToOne` với `User`.
    - Viết DTOs: `RoomPostCreateDto`, `RoomPostResponseDto`, `RoomFilterDto`.
    - Viết `RoomPostRepository`: Hỗ trợ Spring Data JPA Specification để lọc đa tiêu chí (theo khoảng giá, quận huyện, diện tích).
    - Viết `RoomPostController.java`:
      - `POST /api/v1/posts`: Đăng tin tìm bạn ở ghép / cho thuê phòng.
      - `GET /api/v1/posts`: Lấy danh sách tin đăng có phân trang (`Pageable`) và bộ lọc.
      - `GET /api/v1/posts/{id}`: Xem chi tiết tin đăng (tự động tăng view counter).
      - `PUT /api/v1/posts/{id}`: Chỉnh sửa tin đăng của chính mình.
      - `DELETE /api/v1/posts/{id}`: Ẩn hoặc xóa bài đăng.
  - *Đầu ra*: Code Backend hoàn chỉnh, test thành công qua Postman.

- [ ] **Task TD-3.2: Lập trình Backend Module Lời mời Ghép trọ & Đặt lịch hẹn**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 15/09/2026**
  - *Mô tả*:
    - Viết Controller & Service cho `MatchRequest` (Lời mời ghép trọ):
      - `POST /api/v1/match-requests/send`: Gửi lời mời.
      - `PUT /api/v1/match-requests/{id}/respond`: Phản hồi Đồng ý (ACCEPT) hoặc Từ chối (REJECT).
      - Cơ chế Double Opt-in: Khi cả 2 đồng ý, tự động cấp quyền mở khóa số điện thoại (`ContactPermission`).
    - Viết Controller & Service cho `ViewingAppointment` (Lịch hẹn xem phòng):
      - `POST /api/v1/appointments`: Đặt lịch xem phòng.
      - `PUT /api/v1/appointments/{id}/status`: Chủ phòng Xác nhận / Hủy lịch.
      - `GET /api/v1/appointments/my`: Xem danh sách lịch hẹn của tôi.
  - *Đầu ra*: Logic nghiệp vụ chặt chẽ, kiểm tra xung đột thời gian hẹn.

- [ ] **Task TD-3.3: Viết Unit Tests & Integration Tests cho Room & Appointment**
  - *Hạn chót*: ⏰ **23:59 Thứ Hai, 15/09/2026**
  - *Mô tả*: Sử dụng Mockito & MockMvc kiểm tra luồng tạo bài đăng và quy trình phê duyệt lịch hẹn.
  - *Đầu ra*: Test cases chạy pass 100%.

---

### GIAI ĐOẠN 4: LẬP TRÌNH FRONTEND FLUTTER CLIENT (16/09 – 19/09/2026)
*Nhánh Git đề xuất: `feature/room-appointment-ui`*

- [ ] **Task TD-4.1: Xây dựng Giao diện Bảng tin Phòng trọ (Room Feed Screen)**
  - *Hạn chót*: ⏰ **23:59 Thứ Tư, 17/09/2026**
  - *Mô tả*:
    - Tạo `room_feed_screen.dart`:
      - Danh sách bài đăng dạng Card với ảnh đại diện phòng, tiêu đề, địa chỉ, giá thuê/tháng, số người đang cần ghép.
      - Thanh tìm kiếm và bộ lọc nhanh (Lọc theo quận, mức giá, tiện ích: máy lạnh, máy giặt, giờ tự do).
    - Hỗ trợ cuộn vô tận (Infinite Scroll / Phân trang).
  - *Đầu ra*: Màn hình hiển thị mượt mà, load ảnh tối ưu.

- [ ] **Task TD-4.2: Xây dựng Màn hình Chi tiết Phòng trọ & Form Đăng tin**
  - *Hạn chót*: ⏰ **23:59 Thứ Năm, 18/09/2026**
  - *Mô tả*:
    - File `room_detail_screen.dart`: Carousel lướt ảnh phòng, thông tin chủ trọ, danh sách tiện ích, bản đồ vị trí, nút "Đặt lịch xem phòng" và "Nhắn tin trao đổi".
    - File `create_room_post_screen.dart`: Form nhập tiêu đề, giá phòng, tiền cọc, địa chỉ chi tiết, tải ảnh mô tả, chọn tiện ích kèm theo.
  - *Đầu ra*: Giao diện hiện đại, validate dữ liệu kỹ lưỡng.

- [ ] **Task TD-4.3: Xây dựng Màn hình Quản lý Lịch hẹn & Lời mời ghép trọ**
  - *Hạn chót*: ⏰ **23:59 Thứ Sáu, 19/09/2026**
  - *Mô tả*:
    - Tạo `appointment_screen.dart`: Danh sách lịch hẹn đã đặt / được mời với Tab: "Chờ xác nhận", "Đã xác nhận", "Đã hoàn thành", "Đã hủy".
    - Cho phép chủ trọ bấm "Xác nhận" hoặc "Đề xuất giờ khác".
    - Hiển thị số điện thoại liên hệ sau khi đã được cấp quyền (Double Opt-in).
  - *Đầu ra*: Màn hình quản lý tương tác hai chiều rõ ràng.

---

### GIAI ĐOẠN 5: TÍCH HỢP E2E, THI CÔNG QA & BUG TRACKER (20/09 – 22/09/2026)
*Nhánh Git đề xuất: `integration/room-qa`*

- [ ] **Task TD-5.1: Tích hợp Frontend RoomPost & Lịch hẹn với Backend**
  - *Hạn chót*: ⏰ **18:00 Chủ Nhật, 20/09/2026**
  - *Mô tả*: Kết nối toàn bộ luồng đăng tin, tìm kiếm và đặt lịch hẹn xem phòng với cơ sở dữ liệu MySQL thật.
- [ ] **Task TD-5.2: Khởi tạo và Quản trị Bảng theo dõi Lỗi (Bug Tracker)**
  - *Hạn chót*: ⏰ **18:00 Thứ Hai, 21/09/2026**
  - *Mô tả*:
    - Lập file theo dõi lỗi `docs/BUG_TRACKER.md`.
    - Phân loại lỗi theo mức độ nghiêm trọng: Critical (Chặn luồng chính), Major (Lỗi logic), Minor (Lỗi hiển thị UI).
    - Phân công lỗi cho người phụ trách mảng tương ứng sửa triệt để.
- [ ] **Task TD-5.3: Chạy Kiểm thử Toàn diện Hệ thống (Automated & Regression Testing)**
  - *Hạn chót*: ⏰ **23:59 Thứ Ba, 22/09/2026**
  - *Mô tả*: Kiểm thử luồng tích hợp giữa cả 3 bạn (Auth -> Survey -> Matching -> Đăng phòng -> Lịch hẹn).

---

### GIAI ĐOẠN 6: DỮ LIỆU DEMO SẠCH & NGHIỆM THU (23/09/2026)
*Hạn chót toàn dự án: ⏰ **18:00 Thứ Tư, 23/09/2026***

- [ ] **Task TD-6.1: Nạp Bộ Dữ liệu Mẫu Thử nghiệm Hoàn chỉnh (Clean Seed Data)**
  - *Hạn chót*: ⏰ **12:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Cập nhật `database/02_seed_data.sql` với ít nhất 10 người dùng sinh viên có ảnh đại diện đẹp, tiêu chí thực tế, 8 bài đăng phòng trọ thật tại TP.HCM kèm hình ảnh chất lượng.
- [ ] **Task TD-6.2: Nghiệm thu QA lần cuối và bàn giao dự án cho PM Leader**
  - *Hạn chót*: ⏰ **18:00 Thứ Tư, 23/09/2026**
  - *Mô tả*: Xác nhận 0 lỗi Critical, 0 lỗi Major trước khi chính thức chốt mã nguồn.

---

## 🔍 4. BẢNG TỰ KIỂM TRA CHẤT LƯỢNG (SELF-CHECKLIST TRƯỚC KHI TẠO PR)

Trước khi tạo Pull Request vào nhánh `master`, Tiến Đạt tự kiểm tra các tiêu chí sau:
- [ ] Các câu lệnh SQL có chỉ mục (Index) trên các cột thường xuyên tìm kiếm (`district`, `price`, `status`).
- [ ] Khóa ngoại được định nghĩa đúng kiểu dữ liệu và có `ON DELETE CASCADE` phù hợp.
- [ ] APIs lọc bài đăng có phân trang (`page`, `size`), không trả về toàn bộ dữ liệu làm tràn RAM.
- [ ] Form đăng bài có bắt lỗi giá tiền âm, diện tích bằng 0, thiếu số điện thoại.
- [ ] Đã chạy `git pull origin master` trước khi đẩy mã nguồn.
