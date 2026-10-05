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

## Hồi quy vòng đời phiên Flutter (đợt sửa mới — nhóm 1)

- `auth_session_lifecycle_test.dart`: dùng HTTP client giả lập và Completer giữ phản hồi chậm. Kiểm tra logout xóa local ngay nhưng không xóa login mới; refresh/401/response của A không ghi token/cache của B, không retry mutation bằng token B, không phát callback hết phiên mới; refresh cũ không phá single-flight của phiên mới. Đăng nhập/đăng ký đến muộn không khôi phục user sau signOut hoặc ghi đè login mới. Giữ hồi quy refresh thành công trong cùng phiên.
- `avatar_session_lifecycle_test.dart`: giữ riêng response PUT R2/xác nhận avatar; đổi tài khoản, đăng nhập lại cùng tài khoản, signOut hoặc dispose màn hình không khôi phục user/ảnh hay điều hướng từ response cũ. Luồng thành công cùng phiên vẫn cập nhật avatar, giữ thông tin user hiện tại.
- Chạy `flutter test --no-pub test/auth_session_lifecycle_test.dart test/avatar_session_lifecycle_test.dart`, sau đó analyzer và toàn bộ suite. Không dùng Supabase/R2 thật, không sửa SQL hoặc `.env`; kiểm thử thiết bị thật với mạng chậm vẫn cần nghiệm thu riêng.

## Hồi quy cập nhật đồng thời (đợt sửa mới — nhóm 2)

- `RoomAppointmentConcurrencyIntegrationTest`: transaction H2 độc lập, latch giữ snapshot cũ trong persistence context; xác nhận/hủy và hoàn tất/hủy, sửa/duyệt, đóng/duyệt và sửa sau quyết định kiểm duyệt không ghi đè commit khác. Request thua phải rollback; hủy có thể thử lại từ trạng thái đã xác nhận mới.
- Cùng test kiểm tra API JWT thật: version cũ trả `409` cho duyệt/từ chối/đóng; thiếu hoặc sai version trả `400`; quyết định thứ hai từ snapshot cũ không ghi đè admin trước. Chỉ review version mới rõ ràng mới thành công và response trả version đã tăng. `ApiExceptionHandlerTest` giữ `409` cho optimistic lock, không lộ chi tiết kỹ thuật.
- Lệnh không có dirty field vẫn phải kiểm tra version: xác nhận lại lịch đã xác nhận và duyệt lại tin đã duyệt với reason rỗng bị từ chối nếu snapshot đã lỗi thời do hủy/sửa đồng thời.
- `RoomAppointmentVersionMigrationTest`: chạy file migration thật hai lần trên H2 PostgreSQL mode; giữ nội dung, trạng thái đã hủy và version hiện có, điền legacy NULL, kiểm tra default và NOT NULL. Đây là smoke test, không thay thế kiểm thử PostgreSQL/Supabase thực tế.
- `admin_moderation_version_test.dart`: API gửi version đã xem, không logout/retry trên `409`; cả hai màn admin tải lại nhưng chờ quyết định mới. Màn chi tiết xóa lý do cũ, chặn khi tải lại lỗi/thiếu version, khóa gửi trùng. Test dùng HTTP/fake có kiểm soát, không truy cập cloud.
- Chạy focused backend bằng `.\mvnw.cmd test -Dtest=RoomAppointmentConcurrencyIntegrationTest,RoomAppointmentVersionMigrationTest,ApiExceptionHandlerTest`, focused Flutter bằng `flutter test --no-pub test/admin_moderation_version_test.dart test/admin_moderate_post_test.dart`; sau đó toàn bộ Maven/Flutter và analyzer.
- Nghiệm thu thật còn cần hai client với PostgreSQL, đổi tin khi admin đang xem và thao tác lịch hẹn đồng thời. Dừng tất cả backend cũ, sao lưu rồi chạy riêng migration mới; không chạy lại schema/seed và không cho backend cũ ghi đồng thời.

### Regression nhóm 3 — Đăng ký và quy tắc mật khẩu (2026-10-05)

- `AuthInputValidationIntegrationTest`: real controllers/JWT/Bean Validation/BCrypt trên H2. Kiểm tra trường bắt buộc, độ dài email/họ tên/điện thoại/trường học và enum giới tính, trả `400`/`fields` trước khi ghi user/token; gọi service trực tiếp cũng phải validate. Giá trị đúng ở biên vẫn đăng ký được, `OTHER` được chuẩn hóa và điện thoại có thể bỏ trống tại API.
- Cả đăng ký, đổi và đặt lại mật khẩu dùng policy chung: ít nhất 8 ký tự, không chỉ khoảng trắng, tối đa 72 byte UTF-8; không trim giá trị mật khẩu. Test ASCII và Unicode vượt/đúng 72 byte, thiếu hoặc sai mật khẩu mới không đổi hash, thu hồi grant hay tiêu thụ/tăng số lần sai OTP. Đọc lại entity từ DB khi kiểm tra token vì bulk revocation không cập nhật snapshot JPA đang giữ.
- Mật khẩu legacy 6 ký tự vẫn login và dùng làm mật khẩu hiện tại khi đổi được. Input đăng nhập/mật khẩu hiện tại quá 72 byte thất bại như mật khẩu sai, không ném BCrypt `500`. Reset dùng `code` đúng 6 chữ số và `newPassword`; change dùng `oldPassword` và `newPassword`.
- `PasswordPolicyTest`: test thuần policy, không gọi DB hoặc encoder. `auth_input_validation_test.dart`: policy/giới hạn trường, cả ba form, đăng nhập legacy/raw spaces, và hiển thị lỗi `fields` từ API bằng HTTP mock. Các test không kết nối Supabase/R2/SMTP thật.
- Focused backend: `.\mvnw.cmd test -Dtest=AuthInputValidationIntegrationTest,PasswordPolicyTest,RegisterRequestValidationTest,AuthServiceTest,AuthSessionIntegrationTest,MatchRecommendationIntegrationTest,ApiExceptionHandlerTest`. Focused Flutter: `flutter test --no-pub test/auth_input_validation_test.dart test/widget_test.dart test/login_flow_test.dart test/api_business_errors_test.dart`. Sau đó chạy toàn bộ Maven, `flutter analyze --no-pub`, `flutter test --no-pub`, `git diff --check`.
- Kết quả tự động trên working tree ngày 2026-10-05: toàn bộ Maven 422 test đạt (0 fail/error/skip), toàn bộ Flutter 461 test đạt, analyzer không báo lỗi. Nhóm này thêm 34 test backend và 33 test Flutter; các fixture đăng ký cũ được cập nhật thành mật khẩu mới hợp lệ, không siết minimum của login legacy.
- Riêng nhóm 3 không có migration/schema/seed mới. Nghiệm thu trên điện thoại và backend deployed còn cần chạy bản mới, thử đăng ký/đổi/khôi phục mật khẩu và kiểm tra thông báo lỗi trên UI thật; test H2/mock không thay thế nghiệm thu môi trường triển khai.

### Regression nhóm 4 — Đồng bộ hồ sơ và quyền riêng tư (2026-10-05)

- `profile_privacy_sync_test.dart` thêm 33 test HTTP/widget/session: profile HTTP 200 sai body/ID không báo lưu thành công; dùng dữ liệu backend, không tin token trong DTO; giữ token sau refresh và avatar đã xác nhận trong lúc PUT đang chờ; lỗi lưu giữ user hiện có. Phản hồi profile/privacy đến trễ sau đổi phiên không ghi user, cache, báo thành công hoặc đóng màn cũ.
- Công tắc quyền riêng tư chỉ đổi draft; lưu chờ PUT hợp lệ, khóa gửi trùng, lỗi HTTP/body/trạng thái không khớp giữ draft và thử lại được. GET lỗi không giả định trạng thái bật/tắt, không cho lưu cho đến khi tải lại thành công; hủy không gửi PUT. Cache lấy giá trị server xác nhận, đọc cũ không ghi đè lần cập nhật mới.
- Màn hồ sơ quan sát user của phiên hiện tại; sửa qua Cài đặt dùng tên backend trả về, quay lại hồ sơ thấy dữ liệu mới. Lưu quyền riêng tư qua Cài đặt rồi trở về làm mới badge tìm bạn. Badge tải/lỗi/tắt dùng GET thực tế và kiểm tra layout ở chiều rộng 360 logical pixel.
- `ProfileEditIntegrationTest` thêm test sửa hồ sơ với `OTHER`, giữ nguyên giới thiệu/tiêu chí. Cùng `PublicProfileBlockIntegrationTest`, `AppointmentContactPrivacyIntegrationTest` kiểm tra hồi quy backend: 40 test tập trung đạt. Test dùng H2 và HTTP mock, không ghi Supabase/R2 thật.
- Lệnh tập trung: `.\mvnw.cmd test -Dtest=ProfileEditIntegrationTest,PublicProfileBlockIntegrationTest,AppointmentContactPrivacyIntegrationTest` trong backend; `flutter test --no-pub test/profile_privacy_sync_test.dart test/api_service_test.dart test/profile_screen_test.dart test/profile_preferences_refresh_test.dart` trong frontend (73 test đạt). Sau đó toàn bộ Maven, `flutter analyze --no-pub`, `flutter test --no-pub` và `git diff --check`.
- Kết quả cuối trên working tree: `.\mvnw.cmd test` đạt 423 test (0 fail/error/skip); `flutter test --no-pub` đạt 494 test; `flutter analyze --no-pub` không có issue; `git diff --check` không báo lỗi whitespace. Maven chạy bằng JDK 25 hiện có, biên dịch target Java 21. Cảnh báo SDK/deprecation khi chạy test không được coi là xác nhận deploy hay nghiệm thu thật.
- Nhóm 4 không thêm SQL/migration, không thay `.env`, không thay quyền liên hệ/bucket. Cần cập nhật backend/Flutter và kiểm thử thật: đổi avatar rồi lưu hồ sơ, sửa từ Cài đặt, bật/tắt tìm bạn và thử lại khi mạng lỗi trên điện thoại/backend deployed. Chưa nghiệm thu môi trường thật hoặc commit/push các thay đổi của nhóm này.

### Regression nhóm 5 — Tin phòng và bộ lọc (2026-10-05)

- `room_area_amenities_test.dart`: 24 test model/widget/HTTP client thật với transport giả lập. Tin null diện tích mở ô sửa trống, nhập `25,5` gửi JSON `area: 25.5`, giữ chi phí/sức chứa và gửi tiện ích giữ xe thống nhất. Trống/0/âm/NaN/Infinity/chữ chặn PUT; lỗi lưu giữ bản nháp. Tạo mới không gán 28 m² và phải nhập diện tích trước khi tiếp tục.
- Parse CSV/list và bộ lọc nhận hai tên `Giữ xe`/`Chỗ để xe`, khoảng trắng và hoa/thường; không tự suy diễn từ chuỗi phủ định, không mất tiện ích khác, giữ lọc AND. Khởi tạo bộ lọc với tên cũ vẫn chọn đúng chip, đổi draft không sửa dữ liệu đầu vào. Hồi quy reset/hủy/bỏ trần giá nằm trong các test bộ lọc hiện có.
- Feed/chi tiết/danh sách tin dùng diện tích thật hoặc trạng thái chưa cập nhật, không dùng 28 m² giả. Diện tích phần thập phân không bị làm tròn thành số nguyên; lọc diện tích loại dữ liệu thiếu/0. Widget sửa tin chạy chiều rộng 360 logical pixel.
- `RoomPostInputValidationTest` thêm API test JWT/H2: tin có area null được bổ sung 25.5, chuyển PENDING và giữ chi phí/tiện ích/số người. Không thay contract backend hoặc tự rewrite tiện ích legacy trong database.
- Lệnh focused frontend: `flutter test --no-pub test/room_area_amenities_test.dart test/listing_management_test.dart test/room_post_model_test.dart test/room_filter_reset_test.dart test/home_room_filter_reset_test.dart test/room_post_truth_test.dart`. Focused backend: `.\mvnw.cmd test -Dtest=RoomPostInputValidationTest,RoomAppointmentConcurrencyIntegrationTest`; sau đó toàn bộ Maven, Flutter, analyzer và `git diff --check`.
- Kết quả trên working tree: focused Flutter 61 test đạt, focused backend 19 test đạt; toàn bộ `flutter test --no-pub` đạt 518 test, `.\mvnw.cmd test` đạt 424 test (0 fail/error/skip), `flutter analyze --no-pub` không có issue. `git diff --check` không báo lỗi whitespace. Nhóm 5 thêm 24 test Flutter và 1 test backend; Maven dùng JDK 25 hiện có, biên dịch target Java 21.
- Nhóm 5 không thêm SQL/migration, không thay `.env`/R2, không commit/push/deploy. Cần nghiệm thu điện thoại/backend deployed bằng tin cũ thiếu diện tích và tiện ích `Chỗ để xe`, nhập diện tích thật, kiểm duyệt lại rồi thử bộ lọc; test H2/mock không thay thế thao tác thật.

### Regression nhóm 6 — Báo cáo vi phạm (2026-10-05)

- `report_workflow_test.dart` thêm 33 test model/API/widget. Receipt dùng đúng ID backend (200/201/envelope); dữ liệu thiếu/sai không tạo mã giả, không tự resubmit. Luồng gửi dùng router thật, chờ mạng/chặn gửi lặp, lỗi giữ mô tả, điều hướng mang receipt; đóng màn/đổi phiên trong khi chờ không hiện thành công từ response cũ. Trang thiếu receipt không khẳng định đã tiếp nhận; form thiếu đối tượng/nội dung không POST. Widget Trợ giúp và form/receipt chạy chiều rộng 360 logical pixel, không tràn tiêu đề.
- Admin đếm đúng PENDING, giữ lịch sử đã xử lý/bác bỏ, lỗi tải ban đầu không báo số 0; refresh cập nhật count. ID thiếu không bị gán 1. Ghi chú theo ID giữ qua lỗi lưu, hủy dialog, đổi báo cáo và làm mới; không lẫn ghi chú giữa hai báo cáo. Chặn gửi trùng, chỉ chuyển màn thành công khi body xác nhận đúng ID/trạng thái. `admin_report_private_evidence_test.dart` tiếp tục giữ hồi quy signed URL/refresh/response đến trễ và ghi chú đang viết.
- `ReportReceiptIntegrationTest` thêm 3 test controllers/JWT/H2: hai báo cáo trả ID khác nhau khớp bản ghi thật/PENDING; thiếu đối tượng không tạo bản ghi/receipt; xử lý trả đúng ID/trạng thái/ghi chú và danh sách giữ lịch sử, user thường không đọc được danh sách admin. Không gửi HTTP tới R2/cloud DB.
- Focused Flutter: `flutter test --no-pub test/report_workflow_test.dart test/admin_reports_test.dart test/admin_report_private_evidence_test.dart test/api_business_errors_test.dart` (99 test đạt). Focused backend: `.\mvnw.cmd test -Dtest=ReportReceiptIntegrationTest,WorkflowRegressionIntegrationTest,PrivateMediaIntegrationTest,ApiBusinessErrorIntegrationTest` (56 test đạt). Sau đó chạy toàn bộ Maven, Flutter, analyzer và `git diff --check`.
- Kết quả cuối: `flutter test --no-pub` đạt 551 test; `.\mvnw.cmd test` đạt 427 test (0 fail/error/skip); `flutter analyze --no-pub` không có issue; `git diff --check` không báo lỗi whitespace. Sau khi siết assertion đối chiếu chính xác từng ID, chạy lại riêng `ReportReceiptIntegrationTest`: 3 test đạt. Maven dùng JDK 25 hiện có, biên dịch target Java 21. Test mới phát hiện tràn tiêu đề receipt ở 360 px và lỗi này đã được sửa; các lỗi import/lint trong lần viết test đầu đã được khắc phục.
- Không thêm SQL/migration hoặc đổi `.env`, không commit/push/deploy. Nghiệm thu thật còn cần gửi báo cáo từ hồ sơ người đăng/chi tiết liên hệ, đối chiếu ID trong database/admin, thử lỗi mạng khi lưu ghi chú và kiểm tra ảnh minh chứng private trên backend deployed. Không triển khai thông báo kết quả hoặc báo lỗi ứng dụng chung trong nhóm này.

### Regression nhóm 7 — Loại bỏ dữ liệu hiển thị giả (2026-10-05)

- `room_location_truth_test.dart`: 11 test widget. Tin Bình Thạnh, Quận 1/3/7, Thủ Đức và mã khu vực legacy không suy diễn trường/chợ/phút/km. Giữ địa chỉ thực tế kể cả từ khóa HUTECH, thông báo chưa có dữ liệu gần trường/chợ; địa chỉ/khu vực trống hoặc whitespace không bị thay bằng gần trung tâm. Màn 360 px không tràn nội dung; bản đồ vẫn ghi rõ khu vực tham khảo. Nút đặt lịch giữ đúng đối tượng tin.
- `admin_dashboard_test.dart`: giữ hai test bộ đếm cũ, thêm 9 test về API HTTP thật với transport giả lập, API rỗng/lỗi/chờ/thử lại, không dùng dữ liệu tạo bản ghi để dựng nhật ký/biểu đồ. Bộ đếm báo cáo lấy đúng `PENDING`, số 0 chỉ từ response thành công rỗng, lỗi không dùng số cũ. Ba liên kết từ bộ đếm vẫn mở đúng màn duyệt tin/báo cáo/người dùng.
- Lệnh tập trung: `flutter test --no-pub test/admin_dashboard_test.dart test/room_location_truth_test.dart test/room_location_map_test.dart test/room_flow_navigation_test.dart test/room_discovery_test.dart`. Sau đó `flutter analyze --no-pub`, toàn bộ `flutter test --no-pub`, `.\mvnw.cmd test` và `git diff --check`.
- Kết quả cuối trên working tree: 30 test Flutter tập trung đạt; toàn bộ Flutter 571 test đạt; Maven 427 test đạt (0 fail/error/skip); analyzer không có issue; `git diff --check` không có lỗi whitespace. Nhóm 7 thêm 20 test Flutter. Fixture HTTP bổ sung ban đầu thiếu trường `status` của envelope nên test thất bại, đã chỉnh đúng contract và chạy lại focused/full thành công. Maven dùng JDK 25 hiện có, target Java 21 và database H2 test.
- Chưa triển khai khoảng cách/tuyến đường thật, analytics kết nối tuần hoặc nhật ký admin: backend chưa cung cấp dữ liệu/API cần thiết. Không thêm SQL/migration, không thay `.env`, không ghi Supabase/R2, không commit/push/deploy trong nhóm này. Nghiệm thu thật cần chạy Flutter bản mới, mở vị trí của tin thiếu/đủ địa chỉ và dashboard với API thật/lỗi mạng; test widget/H2 không thay thế thử trên điện thoại/backend deployed.
