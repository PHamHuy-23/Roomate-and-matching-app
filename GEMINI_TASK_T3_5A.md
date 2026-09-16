# GEMINI EXECUTION BRIEF — T3.5a / QH-4.2

> Người thực hiện: Gemini  
> Người giao việc và nghiệm thu: PM Lead  
> Branch bắt buộc: `feature/profile-quochuy`  
> Base branch: `origin/master`  
> Phạm vi: Flutter frontend — màn hình hồ sơ cá nhân  
> Trạng thái ban đầu: Đang làm

## 1. Mệnh lệnh thực hiện

Gemini phải triển khai hoàn chỉnh task **T3.5a (QH-4.2)** trên branch hiện tại. Không tự đổi branch, không merge vào `master`, không push thẳng `master`, không sửa trạng thái task thành “Hoàn thành” trước khi PM nghiệm thu.

Trước khi sửa code, bắt buộc đọc:

1. `TASK_ASSIGNMENTS.md`
2. `TASKS_QUOC_HUY.md`, mục `T3.5a / QH-4.2`
3. `frontend/lib/screens/profile_screen.dart`
4. `frontend/lib/screens/survey_screen.dart`
5. `frontend/lib/services/api_service.dart`
6. `frontend/lib/state/auth_session.dart`
7. `frontend/lib/navigation/app_routes.dart`

Không được đọc, sửa hoặc commit `backend/.env`.

## 2. Mục tiêu sản phẩm

Nâng cấp `ProfileScreen` thành màn hình hồ sơ cá nhân hoàn chỉnh, responsive trên mobile và web, sử dụng dữ liệu thật đang có trong ứng dụng/API và không hard-code trạng thái thành công.

### 2.1. Header hồ sơ

- Hiển thị avatar nếu model/API có URL hợp lệ; nếu chưa có thì dùng avatar fallback từ chữ cái đầu của tên.
- Hiển thị họ tên, email, giới tính và các thông tin thực sự có trong `AuthUser`.
- Chỉ hiển thị trường đại học hoặc badge xác thực nếu model/API có dữ liệu chứng minh. Không được hard-code “Đã xác thực” hoặc tên trường giả.
- Nếu dữ liệu chưa được backend hỗ trợ, ghi rõ trong báo cáo blocker; không mở rộng backend trong task frontend này nếu chưa được PM cho phép.

### 2.2. Tiêu chí ghép trọ hiện tại

- Gọi API `getPreferences(userId)` và xử lý đủ các trạng thái loading, success, empty và error.
- Hiển thị các tiêu chí hiện có bằng chip/card dễ đọc, tối thiểu gồm ngân sách, khu vực, thói quen ngủ, mức sạch sẽ, hút thuốc và thú cưng khi dữ liệu tương ứng tồn tại.
- Giá tiền phải được định dạng theo locale Việt Nam.
- Không crash khi API trả thiếu field hoặc người dùng chưa làm khảo sát.
- Có nút thử lại khi tải thất bại.

### 2.3. Cập nhật tiêu chí

- Nút “Cập nhật tiêu chí” phải điều hướng tới `SurveyScreen` cho đúng user hiện tại.
- `SurveyScreen` hiện đã gọi `getPreferences()` khi khởi tạo; không tạo cơ chế truyền dữ liệu trùng lặp nếu không cần thiết.
- Khi quay về từ Survey, Profile phải refresh tiêu chí để phản ánh dữ liệu mới.

### 2.4. Cập nhật thông tin cá nhân

- Giữ chức năng cập nhật họ tên, số điện thoại và giới tính nhưng bổ sung validation hợp lý.
- Không gửi request nếu dữ liệu không hợp lệ.
- Hiển thị loading và thông báo lỗi từ `ApiException`, không nuốt lỗi hoặc chỉ hiện “Cập nhật thất bại” chung chung.
- Sau khi cập nhật thành công, giao diện phải phản ánh dữ liệu mới. Nếu `AuthSession` chưa hỗ trợ cập nhật user, hãy mở rộng frontend state theo cách tối thiểu, có test và không làm mất token.

### 2.5. Cài đặt tài khoản

- Logout phải có dialog xác nhận, xóa phiên và điều hướng về login mà không còn back-stack vào màn hình bảo vệ.
- Với “Đổi mật khẩu”: trước tiên kiểm tra backend/API hiện có. Nếu chưa có endpoint, không được giả lập thành công. Có thể hiển thị trạng thái chưa hỗ trợ và ghi blocker trong báo cáo. Không tự ý mở rộng backend ngoài phạm vi T3.5a.

### 2.6. Chất lượng UI và accessibility

- Responsive ở chiều rộng mobile nhỏ và web desktop.
- Không overflow khi text dài hoặc bàn phím mở.
- Các nút quan trọng phải có tooltip/semantic label phù hợp.
- Giữ phong cách và màu sắc nhất quán với các màn hình hiện tại.

## 3. Yêu cầu kiến trúc

- Không tạo thêm singleton/global state không cần thiết.
- Ưu tiên cho phép inject `ApiService` hoặc dependency cần thiết để widget test không gọi mạng thật.
- Không copy logic parse preference từ `SurveyScreen` sang nhiều nơi nếu có thể tách helper/model dùng chung một cách gọn và trong phạm vi task.
- Không sửa API contract tùy tiện và không hard-code user ID.
- Không thêm package mới nếu có thể dùng package hiện có.
- Chỉ sửa các file liên quan trực tiếp đến T3.5a. Nếu bắt buộc sửa file ngoài phạm vi, giải thích trong báo cáo.

## 4. Kiểm thử bắt buộc

Tạo hoặc cập nhật widget/unit test để bao phủ tối thiểu:

1. Hiển thị loading khi đang tải preference.
2. Hiển thị preference dưới dạng chip/card khi API thành công.
3. Empty state khi user chưa có preference.
4. Error state và nút thử lại khi API lỗi.
5. Validation cập nhật hồ sơ.
6. Điều hướng sang Survey và refresh khi quay lại.
7. Logout xóa session và quay về Login.
8. Không hard-code badge xác thực khi không có dữ liệu.

Chạy và ghi lại kết quả:

```bash
cd frontend
flutter analyze
flutter test
```

Không được báo “pass” nếu lệnh chưa chạy xong hoặc bị treo. Nếu môi trường chặn test, ghi nguyên nhân và bằng chứng ngắn gọn.

## 5. Definition of Done

Task chỉ sẵn sàng gửi PM review khi đáp ứng tất cả:

- [ ] Hoàn thành các mục 2.1–2.6 trong phạm vi dữ liệu/API thực tế.
- [ ] Không hard-code dữ liệu hồ sơ, badge xác thực hoặc kết quả API.
- [ ] Có test cho các trạng thái chính và luồng điều hướng/logout.
- [ ] `flutter analyze` không có lỗi.
- [ ] `flutter test` pass hoặc có blocker môi trường được chứng minh rõ ràng.
- [ ] `git diff --check` pass.
- [ ] Không commit `.env`, file build, file IDE hoặc artifact sinh tự động.
- [ ] Commit message theo Conventional Commits, ví dụ: `feat(frontend): complete personal profile screen`.
- [ ] Điền đầy đủ báo cáo ở mục 7.

## 6. Giới hạn quyền của Gemini

Gemini được phép:

- Sửa code/test Flutter liên quan trực tiếp tới T3.5a.
- Tạo helper/model frontend nếu thật sự cần.
- Commit thay đổi trên `feature/profile-quochuy`.

Gemini không được phép:

- Merge hoặc push vào `master`.
- Đánh dấu task hoàn thành trong `TASK_ASSIGNMENTS.md` hay `TASKS_QUOC_HUY.md`.
- Sửa backend để lách thiếu API mà chưa báo PM.
- Bỏ qua test, xóa test đang fail hoặc hạ thấp assertion để đạt pass giả.
- Đưa secret, token, password hay `backend/.env` vào Git.
- Tự mở rộng sang T3.5b Admin Dashboard.

## 7. Báo cáo bàn giao cho PM — Gemini phải điền

Gemini phải cập nhật mục này trước khi kết thúc công việc.

### 7.1. Trạng thái

- Kết quả: `CHƯA THỰC HIỆN`
- Commit: `CHƯA CÓ`
- Sẵn sàng PM review: `KHÔNG`

### 7.2. File đã thay đổi

- Chưa có.

### 7.3. Chức năng đã hoàn thành

- Chưa có.

### 7.4. Kết quả kiểm thử

- `flutter analyze`: Chưa chạy.
- `flutter test`: Chưa chạy.
- `git diff --check`: Chưa chạy.

### 7.5. Blocker và phần chưa hoàn thành

- Chưa có báo cáo.

### 7.6. Quyết định kỹ thuật đáng chú ý

- Chưa có báo cáo.

### 7.7. Hướng dẫn PM kiểm tra nhanh

- Chưa có báo cáo.
