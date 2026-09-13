# TÀI LIỆU QUYẾT ĐỊNH KIẾN TRÚC (ARCHITECTURAL DECISION RECORD - ADR)

## 📌 ADR-01: Lý do KHÔNG sử dụng Trigger, Stored Procedure và Function trong Cơ sở dữ liệu

**Người quyết định:** PM / Ban Quản Trị Dự Án  
**Trạng thái:** Đã phê duyệt (Giữ nguyên tiến độ)

---

### 1. Bối cảnh (Context)
Trong quá trình thiết kế hệ thống **Roommate Matching Hub**, nhóm phải đối mặt với quyết định: Nên thiết kế CSDL theo chuẩn truyền thống (sử dụng nhiều Trigger, Stored Procedure để xử lý Ràng buộc toàn vẹn và Logic nghiệp vụ) hay đẩy toàn bộ cấu trúc này lên tầng Backend (Modern Backend-Heavy Architecture)?

### 2. Quyết định (Decision)
Nhóm quyết định **KHÔNG SỬ DỤNG** Trigger, Stored Procedure, và Database Functions. Mọi Logic nghiệp vụ (Business Logic) và Ràng buộc toàn vẹn phức tạp (Complex Integrity Constraints) đều được xử lý 100% tại tầng Backend (Spring Boot / Java).

### 3. Lập luận bảo vệ đồ án (Dành cho các thành viên khi bị Hội đồng / Thầy Cô chất vấn)

Nếu Hội đồng đặt câu hỏi: *"Tại sao phần thiết kế CSDL của nhóm không có Trigger hay Stored Procedure để quản lý logic như các đồ án khác?"*, các thành viên sử dụng 4 lập luận thực tế sau để bảo vệ kiến trúc:

#### a) Khả năng Bảo trì và Gỡ lỗi (Maintainability & Debugging)
- Khi logic nằm ở Spring Boot, nhóm có thể dễ dàng đặt Breakpoint, sử dụng công cụ Debug để rà soát, bắt Exception và trả về thông báo lỗi thân thiện cho Client.
- Nếu nhúng logic vào Trigger/SP, CSDL sẽ trở thành một "Hộp đen" (Black box). Lỗi ngầm dưới DB thường chỉ trả về mã lỗi SQL khô khan, khiến việc trace-log và gỡ lỗi cực kỳ khó khăn.

#### b) Tối ưu Kiểm thử Tự động (Automated Testing & CI/CD)
- Ở tầng Backend (Java), nhóm đã thiết lập sẵn thư viện `JUnit` và `Mockito` để tự động test các logic phức tạp.
- Việc thiết lập môi trường Unit Test tự động cho các đoạn mã SQL (Stored Procedure/Trigger) là rất phức tạp. Bằng cách đưa lên Backend, nhóm đảm bảo Code Coverage cao nhất.

#### c) Xóa bỏ Thắt nút cổ chai Hiệu năng (Performance Bottleneck)
- **Scale Backend rất dễ:** Chỉ cần chạy thêm máy chủ/Docker Container (Horizontal Scaling).
- **Scale Database rất khó:** Nếu đẩy thuật toán tính toán xuống chạy bằng Stored Procedure, CPU và RAM của Database Server sẽ nhanh chóng bị vắt kiệt. Giữ CSDL "ngốc nghếch" (chỉ lưu trữ) giúp tối ưu hiệu năng toàn hệ thống.

#### d) Tính Độc lập Hệ quản trị (Database Agnostic)
- Việc dùng công nghệ ORM (JPA/Hibernate) giúp ứng dụng không bị phụ thuộc cứng (Vendor Lock-in) vào MySQL.
- Nếu sau này muốn chuyển đổi sang PostgreSQL hoặc SQL Server, nhóm chỉ cần sửa file cấu hình Spring Boot. Nếu viết cứng bằng Trigger/SP đặc thù của MySQL, việc chuyển đổi là bất khả thi.

### 4. Kết luận
Việc thiếu vắng Trigger/SP không phải là thiếu sót, mà là minh chứng cho việc nhóm đã **áp dụng tư duy thiết kế phần mềm hiện đại của các công ty công nghệ lớn**, ưu tiên khả năng Mở rộng (Scalability), Bảo trì (Maintainability) và Kiểm thử (Testability).
