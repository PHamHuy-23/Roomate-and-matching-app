# Danh sách công việc (Penpot Integration) - Quốc Huy

Đây là file kiểm kê tiến độ thực hiện các màn hình Frontend thuộc phần việc của Quốc Huy, tích hợp từ thiết kế Penpot. 

Quy trình phát triển (AI Rules):
1. Dùng Penpot MCP để soi cấu trúc thiết kế chi tiết (component, token, layout, style).
2. Code giao diện Flutter giống với Penpot.
3. Khi hoàn thành 1 màn hình:
   - Tích chọn (x) vào file này.
   - Báo cáo với người dùng.
   - Commit code vào Git.

## Tiến độ: 30/30 màn hình (100%)

### 1. Module Hồ sơ cá nhân (Profile)
- [x] 24 / Hồ sơ của tôi
- [x] 25 / Chỉnh sửa hồ sơ
- [x] 26 / Ảnh đại diện
- [x] 27 / Cài đặt
- [x] 16 / Hồ sơ bạn ở ghép (Góc nhìn người khác)
- [x] 23 / Người đăng phòng
- [x] 79 / Liên hệ Hoàng Nam
- [x] 66 / Minh Anh

### 2. Module Kết nối & Thông báo (Connections & Notifications)
- [x] 18 / Lời mời kết nối
- [x] 19 / Lời mời đã gửi
- [x] 20 / Kết nối của bạn (hoặc 65 / Kết nối của bạn)
- [x] 21 / Lời mời đã nhận
- [x] 22 / Kết nối thành công
- [x] 56 / Hủy kết nối
- [x] 57 / Người đã chặn
- [x] 28 / Thông báo (và 58 / Thông báo)

### 3. Module Quyền riêng tư & Báo cáo (Privacy & Reports)
- [x] 42 / Quyền riêng tư
- [x] 43 / Báo cáo vi phạm
- [x] 52 / Đã nhận báo cáo
- [x] 59 / Trợ giúp & an toàn

### 4. Module Admin Dashboard
- [x] Admin / Tổng quan hệ thống
- [x] Admin / Quản lý người dùng
- [x] Admin / Chi tiết người dùng
- [x] Admin / Xác nhận khóa tài khoản
- [x] Admin / Tài khoản đã khóa
- [x] Admin / Kiểm duyệt tin đăng
- [x] Admin / Tin đã được duyệt
- [x] Admin / Tin cần được chỉnh sửa
- [x] Admin / Báo cáo vi phạm
- [x] Admin / Đã xử lý báo cáo

---
*Lưu ý: Tuân thủ nghiêm ngặt tiến trình trên với mỗi màn hình.*

## Nhật ký cập nhật thiết kế Penpot

- [x] 01 / Khám phá phòng trọ • Modern Trend 2025 (29/09/2026)
  - Đối chiếu ảnh tham chiếu và đặc tả Design System màu xanh ngọc.
  - Bổ sung tìm kiếm theo ngôn ngữ tự nhiên, bộ lọc commute tới HUTECH, chi phí thực, đánh giá, xác minh, Video Tour, khả năng ở ghép và trạng thái sắp hết phòng.
  - Chuẩn hóa bottom navigation: Home — Map — Roommate — Chat — Profile.
  - Đã export PNG từ Penpot để kiểm tra trực quan sau chỉnh sửa.

- [x] 01B / Khám phá • HTML Tailwind Reference (29/09/2026)
  - Chuyển trực tiếp cấu trúc HTML/Tailwind tham chiếu thành board Penpot 390×844.
  - Giữ hệ màu Material xanh ngọc, Inter + Plus Jakarta Sans, card phòng nổi bật, danh sách gần đây và navigation 4 tab.
  - Dựng thành board riêng để đối chiếu với phương án Modern Trend 2025 và đã export PNG kiểm tra.
  - Nâng board lên đúng kích thước nguồn Stitch 390×1227; bổ sung listing thứ hai, CTA tư vấn và đặt navigation ở cuối canvas.
  - Thay ký tự Unicode bằng SVG Material vector; khôi phục badge `CÒN PHÒNG • Xác thực`, rating `4.9 (18)` và bộ đếm ảnh `1/8` đúng nguồn Stitch.
