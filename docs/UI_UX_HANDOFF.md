# Roommate Hub UI UX Handoff

## Nguồn thiết kế

- Figma: https://www.figma.com/design/PmJPjVfAPQmcwVONgLmGDX
- Penpot (nguồn thay thế, không phụ thuộc quota): `docs/penpot/roommate-hub-master-board.svg`.
- Hướng dẫn import và tái tạo: `docs/penpot/README.md`.
- Trạng thái Penpot: đã import master board, tạo Cover, Design System, 25 tokens và 14 component assets; QA trực quan hoàn tất.
- Kích thước mobile chuẩn: `390 x 844`.
- Dashboard quản trị: khung responsive `1320 x 820`.
- Theme Flutter: `frontend/lib/theme/roommate_hub_theme.dart`.
- Token trung gian: `docs/design-tokens/roommate-hub.tokens.json`.
- App icon vector: `docs/design-assets/roommate-hub-app-icon.svg`.

File Figma dùng ba page do giới hạn của Figma Starter: `00 — Cover`, `01 — Design System`, `02 — Product Screens`. Các nhóm màn hình được phân tách bằng tiêu đề A–I trong page Product Screens.

## Nguyên tắc sản phẩm

1. Giao diện phải tạo cảm giác ấm áp và đáng tin cậy, không mô phỏng ứng dụng hẹn hò.
2. Matching Score luôn đi kèm con số và lý do; không truyền đạt kết quả chỉ bằng màu.
3. Email, điện thoại và kênh liên hệ phải được ẩn trước Double Opt-in.
4. Touch target tối thiểu `44 x 44`; nút chính dùng chiều cao `48` trở lên.
5. Mọi thao tác khóa, chặn, báo cáo, hủy kết nối hoặc ẩn bài cần bước xác nhận và thông báo kết quả.
6. Không hiển thị trạng thái thành công giả khi backend chưa hỗ trợ.

## Danh mục màn hình và yêu cầu

### A Authentication

- `A01 / Welcome`: điểm vào sản phẩm.
- `A02 / Login`: FR-02.
- `A03 / Register`: FR-01.
- `A04 / Verify Email`: FR-22.
- Cần bổ sung từ cùng pattern khi triển khai: quên mật khẩu FR-04, đổi mật khẩu FR-23.

### B Preference Survey

- `B01 / Survey Intro`, `B02 / Survey Budget`, `B03 / Survey Lifestyle`, `B04 / Survey Complete`: FR-07–09, FR-25, FR-42.
- Trọng số mặc định theo API: ngân sách 30%, giờ ngủ 25%, sạch sẽ 20%, hút thuốc 15%, thú cưng 10%.

### C Discover and Matching

- `C01 / Discover`: FR-10–12, FR-26.
- `C02 / Filters`: FR-10, FR-26, FR-41, FR-42.
- `C03 / Candidate Detail`: FR-13.
- `C04 / Compatibility`: FR-12, FR-27.
- Favorite và Compare dùng cùng Candidate Card: FR-39–40.

### D Requests Connections and Privacy

- `D01 / Match Request Sent`: FR-14, FR-28.
- `D02 / Requests`: FR-15–16, FR-43–44.
- `D03 / Accept Request`: FR-15–18.
- `D04 / Contact Permission`: FR-45.

### E Rooms and Appointments

- `E01 / Room Feed`: FR-21, FR-39, FR-46.
- `E02 / Room Detail`: FR-32, FR-53.
- `E03 / Create Room Post`: FR-20; tái sử dụng cho FR-30.
- `E04 / Appointment`: FR-47–48.
- Đóng bài và xác nhận kết quả ở ghép dùng confirmation pattern: FR-31, FR-49.

### F Notifications Profile and Safety

- `F01 / Notifications`: FR-33, FR-50–51.
- `F02 / Profile`: FR-05–06, FR-24.
- `F03 / Safety Center`: FR-34, FR-52.
- `F04 / Report`: FR-35, FR-53.

### G to I Admin and Chat

- `G01 / Admin Dashboard`: tổng quan FR-36–37, FR-54.
- `H01–H05`: inbox, conversation, attachment, safety menu và ended state cho FR-38.
- `I01 / Admin Report Detail`: FR-37.
- `I02 / Admin User Detail`: FR-36.
- `I03 / Admin Room Post Detail`: FR-54.
- `I04 / Admin Decision Confirm`: confirmation và audit trail của FR-37/54.

## Trạng thái API và quy tắc triển khai

- Auth, preferences, matching, match requests, connections, room posts, appointments, notifications, block/report và admin cơ bản đã có contract trong `docs/API_SPECIFICATION.md`.
- FR-38 Chat hiện chỉ là phạm vi optional. Chỉ nối UI chat sau khi backend cung cấp tối thiểu:
  - `GET /connections/{connectionId}/messages`
  - `POST /connections/{connectionId}/messages`
- Attachment cần contract upload riêng. Trước đó nút gửi ảnh phải disabled hoặc hiển thị “Tính năng đang phát triển”.
- Admin moderation bài đăng FR-54 cần endpoint lấy chi tiết bài bị báo cáo, ẩn/khôi phục bài và lưu lý do/audit. Không ánh xạ nhầm sang endpoint xử lý báo cáo nếu backend chưa hỗ trợ.

## Component contract cho Flutter

- Button: `Primary`, `Secondary`, `Tonal`, `Danger`; trạng thái default, disabled, loading.
- Input: default, focused, error; label không được dùng thay placeholder.
- Preference Chip: selected/unselected và tone trung tính/ấm.
- Match Score: `0–100`, luôn có semantic label cho screen reader.
- Candidate Card: avatar, tên, khu vực, ngân sách, score, tối đa ba lý do và CTA.
- Privacy Switch: mỗi trường liên hệ là một quyền độc lập.
- Message Bubble: incoming/outgoing/system; không dùng màu làm dấu hiệu duy nhất.
- Moderation Status: open, reviewing, resolved, dismissed; phải có label chữ.

## Checklist nghiệm thu UI

- Không còn màu Indigo mặc định của Flutter.
- Không hard-code màu/spacing mới ngoài `RoommateHubColors`, `RoommateHubSpacing`, `RoommateHubRadius`.
- Các màn hình có loading, empty, error và retry phù hợp.
- Không lộ liên hệ trước Double Opt-in.
- Không cho gửi chat khi connection không còn `ACTIVE`.
- Admin không được khóa chính tài khoản đang đăng nhập.
- Giá tiền hiển thị theo VND; dữ liệu gửi API vẫn là số nguyên.
- Ngày giờ hiển thị theo múi giờ người dùng, payload API dùng ISO-8601 UTC.

## Ghi chú Penpot QA

Board Penpot/SVG đã bổ sung nội dung chat và admin chi tiết và đã được import vào workspace Penpot. Vòng QA trực quan đã hoàn tất:

1. `I03 / Admin Room Post Detail` hiển thị đúng, không còn lỗi wrapping đáng kể.
2. `H01–H05` và `I01–I04` đã được kiểm tra trong bản export toàn board, không có clipping nghiêm trọng.
3. Penpot có ba page chuẩn, token set `Core` đang active và component library đã được tạo.
4. SVG import được Penpot giữ dưới dạng các layer `svg-raw`; Foundations và Components dùng object native của Penpot.
