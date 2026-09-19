# AGENTS.md — Roommate Hub

## Mục tiêu và phạm vi

- Đây là ứng dụng ghép bạn ở/trọ đang ở giai đoạn prototype (WIP).
- Cấu trúc chính: `backend/` (Spring Boot), `frontend/` (Flutter), `database/` (MySQL), `docs/` (tài liệu học thuật và kỹ thuật).
- Backend dùng Java 21, Spring Boot 4.1.1, JPA, Spring Security/JWT và MySQL. Frontend dùng Flutter/Dart, Provider và HTTP.

## Nguồn sự thật và thứ tự ưu tiên

1. Yêu cầu hiện tại của người dùng/PM.
2. Brief dành riêng cho task trên branch hiện tại, ví dụ `GEMINI_TASK_*.md`.
3. `TASK_ASSIGNMENTS.md` là nguồn sự thật về mã task, người phụ trách, deadline và trạng thái tổng.
4. `TASKS_QUOC_HUY.md`, `TASKS_QUANG_HUY.md`, `TASKS_TIEN_DAT.md` mô tả phạm vi và tiêu chí chi tiết của từng người; không được mâu thuẫn với file tổng.
5. Code, schema và test đang được Git theo dõi là nguồn sự thật kỹ thuật. `PROJECT_MEMORY.md` chỉ là bối cảnh lịch sử cục bộ; luôn kiểm chứng thông tin dễ lỗi thời bằng Git và các file task hiện hành.

Khi hai nguồn mâu thuẫn, không tự chọn phương án làm thay đổi phạm vi. Báo rõ mâu thuẫn cho PM và chỉ tiếp tục phần chắc chắn.

## Quy trình làm việc

- Không code, commit hoặc push trực tiếp lên `master`.
- Mỗi task dùng branch riêng theo `feature/<tinh-nang>-<ten>`, tạo từ `origin/master` mới nhất, trừ khi PM chỉ định khác.
- Chỉ sửa file thuộc phạm vi task. Giữ nguyên thay đổi không liên quan của người khác.
- Trước khi sửa, đọc brief task, file task cá nhân và các tài liệu/API liên quan.
- Không tự đánh dấu task “Hoàn thành”. Chỉ cập nhật sau khi có đủ bằng chứng kiểm thử, PM nghiệm thu và thay đổi đã được merge vào `master`.
- Tạo Pull Request vào `master`; không tự merge nếu chưa đạt review, CI và quy tắc bảo vệ nhánh.
- Commit nhỏ, rõ nghĩa, theo kiểu `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`, `docs(scope): ...`.

## Bảo mật và cấu hình cục bộ

- Tuyệt đối không commit secret, mật khẩu, token hoặc file `.env`.
- Mỗi thành viên tự cấu hình MySQL cục bộ bằng biến môi trường/file local được ignore; tài liệu và file mẫu chỉ chứa giá trị giả an toàn.
- Không hard-code mật khẩu DB vào source, test, tài liệu hoặc báo cáo.
- Không giả lập API thành công nếu backend chưa hỗ trợ; hiển thị trạng thái phù hợp và ghi blocker.

## Kiểm thử tối thiểu

- Backend: chạy `cd backend` rồi `.\mvnw.cmd test`.
- Frontend: chạy `cd frontend`, `flutter analyze` và `flutter test`.
- Chạy thêm test tập trung cho phần thay đổi. Không tuyên bố pass nếu chưa chạy; nếu không chạy được, ghi chính xác lệnh, lỗi và blocker.
- Trước commit: kiểm tra `git diff`, `git diff --check` và `git status`; chỉ stage đúng file của task.

## Báo cáo bàn giao

- Nêu branch/commit, file đã đổi, chức năng hoàn thành, kết quả từng lệnh test và phần còn thiếu/blocker.
- Không ghi nội dung “đã xong” khi mới chỉ tạo khung, mock dữ liệu hoặc chưa kết nối luồng thực tế.
- Không thêm asset, tool, dependency hay tài liệu không được sử dụng trực tiếp bởi task.

## Quy tr�nh th?c hi?n m�n h�nh Frontend (Penpot)
- B?t bu?c d�ng Penpot MCP d? xem thi?t k? g?c.
- M?i khi t?o xong 1 m�n h�nh: 1) B�o c�o ti?n d? cho PM, 2) C?p nh?t file markdown tracking (vd: TASKS_QUOC_HUY_PENPOT.md), 3) Th?c hi?n git commit ngay l?p t?c.
