# KẾ HOẠCH KIỂM THỬ TỔNG THỂ (QA TEST PLAN)
**Dự án**: Nền tảng Tìm bạn cùng thuê trọ và Ghép bạn trọ theo tiêu chí (Roommate Matching Hub)

## 1. Mục tiêu kiểm thử
Đảm bảo 54 yêu cầu chức năng (FRs) hoạt động chính xác, ổn định và không có lỗi nghiêm trọng (Critical/Major) trước thời điểm bàn giao dự án.

## 2. Phạm vi kiểm thử (Scope)
### In-scope (Trong phạm vi)
- Luồng Đăng ký, Đăng nhập và Xác thực người dùng (Authentication).
- Luồng Đăng bài phòng trọ, Tìm kiếm, Lọc phân trang theo tiêu chí.
- Luồng Gửi và Nhận lời mời ghép đôi (Cơ chế Double Opt-in mở khóa liên hệ).
- Luồng Đặt lịch hẹn xem phòng trực tiếp (Tạo, Xác nhận, Hủy hẹn).
- Luồng Báo cáo vi phạm (Report).

### Out-of-scope (Ngoài phạm vi)
- Hiệu năng hệ thống dưới tải trọng lớn (Load Testing không bắt buộc ở Giai đoạn 1).
- Tích hợp cổng thanh toán trực tuyến (nếu có bổ sung sau).

## 3. Tiêu chuẩn chấp nhận lỗi (Bug Severity Matrix)

| Mức độ | Định nghĩa và Hậu quả | Ví dụ cụ thể |
| :--- | :--- | :--- |
| **Critical** (Nghiêm trọng) | Lỗi khiến hệ thống ngừng hoạt động (Crash), không thể truy cập, hoặc vi phạm nghiêm trọng tính bảo mật. | Hệ thống sập (500 Error liên tục); rò rỉ mật khẩu người dùng; lộ số điện thoại khi chưa được cho phép. |
| **Major** (Lớn) | Tính năng cốt lõi không thể sử dụng nhưng hệ thống không sập. Không có cách khắc phục tạm thời. | Không gửi được lời mời ghép trọ; tính sai % Matching; sai lệch giá phòng đăng so với thực tế. |
| **Minor** (Nhỏ) | Lỗi nhỏ, không ảnh hưởng đến luồng công việc chính, thường liên quan đến thẩm mỹ UI/UX. | Lệch font chữ; sai vị trí nút bấm; text tiếng Anh chưa được dịch sang tiếng Việt; tràn viền nhỏ. |

## 4. Ma trận truy xuất nguồn gốc yêu cầu (Traceability Matrix)

| Mã Yêu Cầu (FR) | Tên Chức Năng | Kịch Bản Kiểm Thử (Test Case) Tương Ứng | Kết Quả Mong Đợi |
| :--- | :--- | :--- | :--- |
| **FR-01** | Đăng ký tài khoản mới | **TC-AUTH-01**: Điền form hợp lệ và nhấn Đăng ký. | Lưu CSDL thành công, chuyển hướng trang Login. |
| **FR-12** | Đăng bài phòng trọ | **TC-POST-01**: Nhập đủ tiêu đề, giá, quận, nhấn Đăng. | Bài đăng hiện lên bảng tin trang chủ ngay lập tức. |
| **FR-25** | Gửi lời mời ghép đôi | **TC-MATCH-01**: Gửi lời mời tới user khác. | Nút chuyển thành "Đã gửi", bên kia nhận được Ping. |
| **FR-26** | Double Opt-in mở khóa liên hệ | **TC-MATCH-02**: Bên nhận nhấn "Đồng ý" lời mời. | SĐT/Zalo của 2 bên hiển thị công khai cho nhau xem. |
| **FR-27** | Từ chối ghép đôi | **TC-MATCH-03**: Bên nhận nhấn "Từ chối" lời mời. | Lời mời bị hủy, thông tin liên lạc được giữ kín tuyệt đối. |
| **FR-40** | Đặt lịch hẹn xem phòng | **TC-APPT-01**: Đặt lịch hẹn với chủ phòng hợp lệ. | Sinh ra 1 lịch hẹn ở trạng thái `PENDING`. |

## 5. Bộ kiểm thử hồi quy cho sáu nhóm sửa lỗi

Các test bên dưới chạy trên database H2 tạm hoặc API giả lập có kiểm soát, không dùng dữ liệu Supabase/R2 thật. Không đánh dấu task hoàn thành/nghiệm thu chỉ dựa trên test tự động.

| Nhóm | Bằng chứng tự động chính | Điều kiện cần giữ |
|---|---|---|
| 1 — Quyền xem liên hệ | `AppointmentContactPrivacyIntegrationTest`, `appointment_contact_privacy_test.dart` | Không lộ điện thoại khi chưa đủ quyền; chặn/khóa/hủy kết nối thu hồi quyền ở lần đọc tiếp theo. |
| 2 — Chặn và lịch hẹn | `AppointmentEligibilityIntegrationTest`, `PublicProfileBlockIntegrationTest` | Chặn hai chiều, trạng thái tài khoản/tin phòng và quyền chủ phòng; vẫn giữ lịch sử và quyền hủy phù hợp. |
| 3 — Khóa/mở khóa rõ ràng | `AdminUserStatusIntegrationTest`, `admin_user_status_api_test.dart`, `admin_user_status_widget_test.dart` | Lệnh idempotent, không tự khóa, không báo thành công sai ID/trạng thái. |
| 4 — Ảnh riêng tư R2 | `PrivateMediaIntegrationTest`, `R2StorageServiceTest`, `private_upload_api_test.dart`, `admin_report_private_evidence_test.dart`, `chat_loading_test.dart` | Bucket private, key/purpose/owner hợp lệ, URL ngắn hạn đúng người xem; giữ draft khi gửi lỗi. |
| 5 — Bộ lọc và hồ sơ | `room_filter_reset_test.dart`, `home_room_filter_reset_test.dart`, `profile_preferences_refresh_test.dart` | Reset không có trần giá ẩn; hủy không áp dụng; lưu khảo sát thành công tải lại tiêu chí, request cũ không ghi đè. |
| 6 — Lỗi API | `ApiBusinessErrorIntegrationTest`, `ApiExceptionHandlerTest`, `Group6ServiceErrorsTest`, `AuthServiceTest`, `api_business_errors_test.dart` | Đúng mã HTTP và không ghi dữ liệu khi từ chối; lỗi thật vẫn 500 nhưng không lộ chi tiết; lỗi nghiệp vụ không làm client mất phiên/giả thành công. |

Lệnh kiểm tra:

```powershell
# Từ thư mục backend
.\mvnw.cmd test
# Từ thư mục frontend
flutter analyze --no-pub
flutter test --no-pub
```

Kiểm thử nghiệm thu trên môi trường thật còn cần: thao tác chạm slider trên điện thoại nhỏ, luồng lưu khảo sát–tải hồ sơ với API thật, upload/read URL private R2 và luồng SMTP/Supabase. Kiểm tra riêng việc thoát khảo sát trong lúc request lưu đang chờ; đây chưa được xử lý trong nhóm 5/6. Không chạy lại schema/seed hoặc sửa dữ liệu thật để thực hiện bộ hồi quy tự động này.

---
*Tài liệu được soạn thảo phục vụ Giai đoạn 5 (Tích hợp E2E & Thi công QA).*
