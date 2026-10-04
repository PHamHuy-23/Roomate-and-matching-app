# ROOMMATE HUB — REST API SPECIFICATION

> Phiên bản: `v1.0`  
> Ngày ban hành: `12/09/2026`  
> Base URL: `http://localhost:8080/api/v1`  
> Định dạng dữ liệu: `application/json; charset=UTF-8`

Tài liệu này là API Contract dùng chung giữa Backend Spring Boot và Frontend Flutter. Mọi thay đổi làm sai tên endpoint, HTTP method, request/response schema hoặc mã trạng thái trong tài liệu phải được thống nhất trước giữa các thành viên.

## 1. Quy ước chung

### 1.1. Xác thực

Các endpoint không ghi `Public` yêu cầu header:

```http
Authorization: Bearer <access_token>
```

- Access token: JWT ký bằng `HMAC-SHA256`, thời hạn `24 giờ`.
- Refresh token: thời hạn `7 ngày`, chỉ dùng tại endpoint refresh token.
- Access token mới chứa claim `refresh_token_id`, trỏ tới bản ghi phiên trong `refresh_tokens` (không chứa refresh token thô hoặc hash). Backend chỉ chấp nhận grant chưa thu hồi, chưa hết hạn và mới nhất của đúng tài khoản. Đăng nhập lại hoặc xoay vòng refresh token vô hiệu hóa access token trước đó; logout/đổi hoặc đặt lại mật khẩu thu hồi toàn bộ grant. Không phụ thuộc vào việc các thao tác xảy ra cùng giây.
- Sau khi nâng cấp backend, JWT cũ không có claim này sẽ nhận `401`: client cần refresh bằng refresh token còn hiệu lực hoặc đăng nhập lại. Không cần migration SQL cho thay đổi phiên này.
- Backend lấy `userId`, `email` và `role` từ JWT. Client không được truyền `userId` của người đang đăng nhập để thay thế danh tính trong token.
- Endpoint `/admin/**` yêu cầu role `ROLE_ADMIN`.

### 1.2. Generic API Response

Mọi response thành công và thất bại đều dùng một lớp bao bọc thống nhất:

```json
{
  "status": 200,
  "message": "Thao tác thành công",
  "data": {}
}
```

Khi không có dữ liệu trả về, `data` là `null`. Response danh sách có phân trang dùng cấu trúc:

```json
{
  "status": 200,
  "message": "Lấy danh sách thành công",
  "data": {
    "items": [],
    "page": 0,
    "size": 20,
    "totalElements": 0,
    "totalPages": 0,
    "sort": "createdAt,desc"
  }
}
```

### 1.3. Error Response

```json
{
  "status": 400,
  "message": "Dữ liệu không hợp lệ",
  "data": null,
  "fields": {
    "email": "Email không đúng định dạng"
  },
  "timestamp": "2026-09-12T10:30:00Z"
}
```

| HTTP status | Ý nghĩa | Trường hợp điển hình |
|---:|---|---|
| `200 OK` | Đọc/cập nhật thành công | GET, PUT, PATCH |
| `201 Created` | Tạo tài nguyên thành công | Đăng ký, tạo bài đăng, gửi yêu cầu |
| `204 No Content` | Xóa/hủy thành công | Không cần response body |
| `400 Bad Request` | Thiếu trường hoặc validation thất bại | Email sai định dạng, giá âm |
| `401 Unauthorized` | Chưa đăng nhập hoặc token không hợp lệ/hết hạn | Thiếu Bearer token |
| `403 Forbidden` | Không có quyền thực hiện | User gọi API Admin, sửa tài nguyên người khác |
| `404 Not Found` | Không tìm thấy tài nguyên | ID không tồn tại |
| `409 Conflict` | Xung đột/trùng lặp nghiệp vụ | Email đã tồn tại, đã gửi lời mời |
| `422 Unprocessable Entity` | Dữ liệu hợp lệ về cú pháp nhưng không thể xử lý nghiệp vụ | Chưa hoàn thành khảo sát để Matching |
| `500 Internal Server Error` | Lỗi ngoài dự kiến phía server | Không để lộ stack trace cho client |

Đây là dạng lỗi từ MVC/advice hiện tại: `fields` chỉ có khi Bean Validation thất bại; chưa trả mã nghiệp vụ `code`, danh sách `errors` hay `path`. Lỗi do Spring Security chặn trước controller vẫn dùng `401/403` từ filter, không bảo đảm cùng JSON body; Flutter sử dụng mã HTTP và thông báo dự phòng khi không có `message`.

### 1.4. Quy ước dữ liệu

- Thời gian dùng ISO-8601 UTC, ví dụ `2026-09-12T10:30:00Z`.
- Tiền tệ dùng số nguyên VND, ví dụ `2500000`; không dùng `double` cho giá tiền trong contract.
- Phân trang bắt đầu từ `page=0`; mặc định `size=20`, tối đa `size=100`.
- Trường enum dùng chữ in hoa: `ACTIVE`, `PENDING`, `ACCEPTED`.
- Trường không được phép cập nhật không xuất hiện trong request; server bỏ qua hoặc trả `400` theo validation thống nhất.

## 2. Danh mục endpoint

Tổng cộng: **48 endpoints**.

### 2.1. Auth & Account — 9 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 1 | POST | `/auth/register` | Public | Đăng ký tài khoản | FR-01 |
| 2 | POST | `/auth/login` | Public | Đăng nhập và cấp token | FR-02 |
| 3 | POST | `/auth/refresh` | Public | Cấp cặp token mới | FR-02 |
| 4 | POST | `/auth/logout` | User | Thu hồi refresh token | FR-03 |
| 5 | POST | `/auth/verify-email` | Public | Xác minh email bằng mã | FR-22 |
| 6 | POST | `/auth/forgot-password` | Public | Gửi mã đặt lại mật khẩu | FR-04 |
| 7 | POST | `/auth/reset-password` | Public | Đặt mật khẩu mới bằng mã | FR-04 |
| 8 | PUT | `/auth/change-password` | User | Đổi mật khẩu khi đã đăng nhập | FR-23 |
| 9 | GET | `/auth/me` | User | Lấy thông tin tài khoản hiện tại | FR-06 |

### 2.2. Profile & Preferences — 7 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 10 | GET | `/profiles/me` | User | Xem hồ sơ cá nhân | FR-06 |
| 11 | PUT | `/profiles/me` | User | Cập nhật hồ sơ cá nhân | FR-05 |
| 12 | PATCH | `/profiles/me/search-status` | User | Bật/tắt trạng thái tìm roommate | FR-24 |
| 13 | GET | `/profiles/{candidateId}` | User | Xem hồ sơ ứng viên theo quyền riêng tư | FR-13 |
| 14 | GET | `/preferences/me` | User | Xem tiêu chí khảo sát | FR-07–09 |
| 15 | PUT | `/preferences/me` | User | Tạo mới hoặc cập nhật tiêu chí | FR-07–09 |
| 16 | PUT | `/preferences/me/priorities` | User | Cập nhật trọng số/mức ưu tiên | FR-25 |

### 2.3. Search & Matching — 4 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 17 | GET | `/matching/recommendations` | User | Danh sách gợi ý theo điểm giảm dần | FR-11, FR-12, FR-26 |
| 18 | GET | `/matching/search` | User | Tìm ứng viên theo bộ lọc | FR-10, FR-26 |
| 19 | GET | `/matching/candidates/{candidateId}` | User | Chi tiết ứng viên ẩn danh | FR-13 |
| 20 | GET | `/matching/candidates/{candidateId}/compatibility` | User | Điểm và lý do tương thích | FR-12, FR-27 |

### 2.4. Match Requests & Connections — 9 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 21 | POST | `/match-requests` | User | Gửi yêu cầu ghép đôi | FR-14 |
| 22 | GET | `/match-requests?box=received` | User | Danh sách yêu cầu đã nhận | FR-15–16 |
| 23 | GET | `/match-requests?box=sent` | User | Danh sách yêu cầu đã gửi | FR-14, FR-28 |
| 24 | PATCH | `/match-requests/{requestId}/accept` | User | Chấp nhận yêu cầu | FR-15, FR-17 |
| 25 | PATCH | `/match-requests/{requestId}/reject` | User | Từ chối yêu cầu | FR-16 |
| 26 | DELETE | `/match-requests/{requestId}` | User | Hủy yêu cầu đang `PENDING` | FR-28 |
| 27 | GET | `/connections` | User | Xem danh sách kết nối | FR-18–19 |
| 28 | GET | `/connections/{connectionId}` | User | Xem kết nối và liên hệ đã mở khóa | FR-18 |
| 29 | DELETE | `/connections/{connectionId}` | User | Hủy kết nối | FR-29 |

### 2.5. Room Posts — 5 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 30 | GET | `/room-posts` | User | Danh sách/lọc bài đăng còn hiệu lực | FR-21 |
| 31 | POST | `/room-posts` | User | Tạo bài đăng phòng | FR-20 |
| 32 | GET | `/room-posts/{postId}` | User | Xem chi tiết bài đăng | FR-32 |
| 33 | PUT | `/room-posts/{postId}` | Owner | Chỉnh sửa bài đăng | FR-30 |
| 34 | PATCH | `/room-posts/{postId}/close` | Owner | Đóng bài đăng | FR-31 |

### 2.6. Viewing Appointments — 5 endpoints

| # | Method | Endpoint | Quyền | Mô tả |
|---:|---|---|---|---|
| 35 | POST | `/appointments` | User | Đặt lịch xem phòng |
| 36 | GET | `/appointments?role=requester` | User | Lịch do mình đặt |
| 37 | GET | `/appointments?role=host` | User | Lịch tại bài đăng của mình |
| 38 | PATCH | `/appointments/{appointmentId}/confirm` | Host | Xác nhận lịch hẹn |
| 39 | PATCH | `/appointments/{appointmentId}/cancel` | Participant | Hủy lịch hẹn |

### 2.7. Notifications, Safety & Admin — 9 endpoints

| # | Method | Endpoint | Quyền | Mô tả | FR |
|---:|---|---|---|---|---|
| 40 | GET | `/notifications` | User | Xem thông báo | FR-33 |
| 41 | PATCH | `/notifications/{notificationId}/read` | User | Đánh dấu đã đọc | FR-33 |
| 42 | POST | `/blocks` | User | Chặn người dùng | FR-34 |
| 43 | DELETE | `/blocks/{blockedUserId}` | User | Bỏ chặn người dùng | FR-34 |
| 44 | POST | `/reports` | User | Báo cáo user hoặc bài đăng | FR-35 |
| 45 | GET | `/admin/users` | Admin | Danh sách tài khoản | FR-36 |
| 46 | PATCH | `/admin/users/{userId}/status` | Admin | Khóa/mở tài khoản | FR-36 |
| 47 | GET | `/admin/reports` | Admin | Danh sách báo cáo | FR-37 |
| 48 | PATCH | `/admin/reports/{reportId}/resolve` | Admin | Xử lý báo cáo | FR-37 |

Nhắn tin trong kết nối (FR-38) là phạm vi ưu tiên thấp. Nếu triển khai, bổ sung `GET /connections/{connectionId}/messages` và `POST /connections/{connectionId}/messages` mà không thay đổi contract của các nhóm cốt lõi.

## 3. Đặc tả chi tiết Auth API

### 3.1. POST `/auth/register`

`Public` — Tạo tài khoản mới và gửi mã xác minh email.

Request:

```json
{
  "email": "huy@gmail.com",
  "password": "Roommate@123",
  "confirmPassword": "Roommate@123",
  "fullName": "Trần Quang Huy",
  "gender": "MALE",
  "phone": "0970780778"
}
```

Validation:

- `email`: bắt buộc, đúng định dạng, tối đa 100 ký tự và chưa tồn tại.
- `password`: 8–72 ký tự, có chữ hoa, chữ thường, chữ số và ký tự đặc biệt.
- `confirmPassword`: phải trùng `password`.
- `fullName`: bắt buộc, 2–100 ký tự.
- `gender`: `MALE`, `FEMALE` hoặc `OTHER`.
- `phone`: tùy chọn, 10–15 chữ số.

Response `201 Created`:

```json
{
  "status": 201,
  "message": "Đăng ký thành công, vui lòng xác minh email",
  "data": {
    "userId": 5,
    "email": "huy@gmail.com",
    "emailVerified": false,
    "createdAt": "2026-09-12T10:30:00Z"
  }
}
```

Lỗi: `400` validation, `409 EMAIL_ALREADY_EXISTS`.

### 3.2. POST `/auth/login`

`Public` — Xác thực bằng email/mật khẩu.

Request:

```json
{
  "email": "huy@gmail.com",
  "password": "Roommate@123"
}
```

Response `200 OK`:

```json
{
  "status": 200,
  "message": "Đăng nhập thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "refreshExpiresIn": 604800,
    "user": {
      "id": 1,
      "email": "huy@gmail.com",
      "fullName": "Trần Quang Huy",
      "gender": "MALE",
      "role": "ROLE_USER",
      "status": "ACTIVE",
      "emailVerified": true
    }
  }
}
```

Lỗi: `400` validation, `401 INVALID_CREDENTIALS`, `403 ACCOUNT_LOCKED` hoặc `EMAIL_NOT_VERIFIED`.

### 3.3. POST `/auth/refresh`

Request:

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
}
```

Response `200 OK`: trả `accessToken`, `refreshToken`, `tokenType`, `expiresIn` và `refreshExpiresIn` như login. Refresh token cũ bị thu hồi sau khi xoay vòng token.

Lỗi: `401 REFRESH_TOKEN_INVALID` hoặc `REFRESH_TOKEN_EXPIRED`.

### 3.4. POST `/auth/logout`

Request:

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
}
```

Response `200 OK`:

```json
{
  "status": 200,
  "message": "Đăng xuất thành công",
  "data": null
}
```

### 3.5. POST `/auth/verify-email`

Request: `{ "email": "huy@gmail.com", "verificationCode": "483921" }`  
Response `200`: xác minh thành công.  
Lỗi: `400 VERIFICATION_CODE_INVALID`, `410 VERIFICATION_CODE_EXPIRED`.

### 3.6. POST `/auth/forgot-password`

Request: `{ "email": "huy@gmail.com" }`  
Response luôn là `200` với thông báo chung để tránh tiết lộ email có tồn tại hay không.

### 3.7. POST `/auth/reset-password`

Request:

```json
{
  "email": "huy@gmail.com",
  "resetCode": "572910",
  "newPassword": "NewPassword@123",
  "confirmPassword": "NewPassword@123"
}
```

Response `200`: đặt lại mật khẩu thành công và thu hồi toàn bộ refresh token cũ.

### 3.8. PUT `/auth/change-password`

Request:

```json
{
  "currentPassword": "Roommate@123",
  "newPassword": "NewPassword@123",
  "confirmPassword": "NewPassword@123"
}
```

Response `200`: đổi mật khẩu thành công.  
Lỗi: `400 PASSWORD_CONFIRMATION_MISMATCH`, `401 CURRENT_PASSWORD_INCORRECT`.

### 3.9. GET `/auth/me`

Response `200`:

```json
{
  "status": 200,
  "message": "Lấy thông tin tài khoản thành công",
  "data": {
    "id": 1,
    "email": "huy@gmail.com",
    "fullName": "Trần Quang Huy",
    "gender": "MALE",
    "phone": "0970780778",
    "avatarUrl": null,
    "role": "ROLE_USER",
    "status": "ACTIVE",
    "emailVerified": true,
    "searchingForRoommate": true
  }
}
```

## 4. Đặc tả chi tiết Matching API

### 4.1. User Preference schema

Request dùng tại `PUT /preferences/me`:

```json
{
  "targetDistrict": "Thu Duc",
  "budgetAmount": 2500000,
  "sleepHabit": 3,
  "cleanlinessLevel": 4,
  "isSmoking": false,
  "allowPets": false,
  "bioDescription": "Sinh viên IT, yên tĩnh",
  "priorities": {
    "budget": "REQUIRED",
    "sleepHabit": "IMPORTANT",
    "cleanliness": "IMPORTANT",
    "smoking": "REQUIRED",
    "pets": "OPTIONAL"
  }
}
```

Validation:

- `targetDistrict`: bắt buộc, tối đa 100 ký tự.
- `budgetAmount`: số nguyên, tối thiểu `500000` VND.
- `sleepHabit`: từ `1` đến `3`.
- `cleanlinessLevel`: từ `1` đến `5`.
- `isSmoking`, `allowPets`: bắt buộc.
- Priority: `REQUIRED`, `IMPORTANT`, `OPTIONAL`.

Validation của endpoint hiện tại `PUT /api/v1/profile/preferences/{userId}`:

- Ngân sách phải hữu hạn; `budgetAmount >= 500000`. `budgetMin` và `budgetMax` cùng có hoặc cùng bỏ trống (tương thích dữ liệu cũ), với `0 <= budgetMin <= budgetMax` và `budgetMax >= 500000`.
- `sleepHabit` trong `1..3`, `cleanlinessLevel` trong `1..5`, khu vực không trống và tối đa 100 ký tự. Vi phạm trả `400`, không ghi đè tiêu chí đang lưu.
- Flutter giữ nguyên khoảng ngân sách hợp lệ đã lưu kể cả ngoài khoảng hiển thị mặc định 1–15 triệu. Nếu tải tiêu chí thất bại hoặc khoảng lưu sai cấu trúc, hiển thị lỗi và cho thử lại; không dùng mặc định để ghi đè dữ liệu cũ.
- Chuẩn hóa khu vực theo danh mục hiện có của ứng dụng: ví dụ `Thu Duc`, `Thủ Đức`, `TP. Thủ Đức`, `Thành phố Thủ Đức`, `Thủ Đức, TP.HCM` cùng khóa `Thu Duc`; bỏ khác biệt hoa/thường, dấu và khoảng trắng khi nhận diện tên. Tên ngoài danh mục được giữ nguyên (chỉ cắt/gộp khoảng trắng), không thay bằng Bình Thạnh. Đây là quy tắc tương thích tên cũ, không phải tra cứu địa giới/tọa độ.
- `PUT /profile/preferences/{userId}`, tạo/sửa tin phòng lưu khóa chuẩn cho khu vực nhận diện được. Response tiêu chí, hồ sơ công khai, gợi ý và tin phòng cũng trả khóa chuẩn cho dữ liệu cũ mà không ghi lại bản ghi khi đọc. Matching vẫn lọc cứng cùng khu vực, nhưng so sánh khóa chuẩn sau khi lấy ứng viên theo giới tính để nhận diện các bản ghi cũ; không thay đổi quy tắc khóa tài khoản, ngừng tìm bạn, chặn hoặc giới tính hai chiều. Với dữ liệu lớn, cần tối ưu truy vấn bằng khóa khu vực được lập chỉ mục; hiện không thêm cột/migration.
- Flutter dùng chung danh mục cho khảo sát, hồ sơ và bộ lọc. Gợi ý có nhiều cách viết của cùng khu vực chỉ tạo một lựa chọn; tìm kiếm nhận tên có/không dấu. Bộ lọc phòng ưu tiên trường `district`, chỉ tìm tên có ranh giới từ trong địa chỉ nếu trường này trống; Quận 1 không khớp Quận 10/11/12. Khảo sát giữ và cho lưu tên cũ ngoài danh mục. Không cần chạy SQL cho nhóm sửa khu vực này.
- Khi tạo/cập nhật tin phòng: `maxOccupants >= 1`, `0 <= currentOccupants <= maxOccupants`. Cập nhật một phần kiểm tra cả giá trị đang lưu: không giảm sức chứa xuống thấp hơn số người hiện tại. Vi phạm trả `400` trước khi thay đổi nội dung/trạng thái tin.
- Không có thay đổi schema SQL cho các kiểm tra này; dữ liệu cũ không được tự động sửa.

Các trường bổ sung của khảo sát (nhóm 6), tại GET/PUT `/api/v1/profile/preferences/{userId}`:

- `moveInDate`: ngày chuyển vào, ISO date `yyyy-MM-dd` (không có giờ/múi giờ). Ngày lưu trong quá khứ vẫn được đọc/giữ nguyên; khi chọn ngày mới, Flutter mở lịch từ ngày hiện tại, không dùng ngày cứng `01/10/2026`.
- `roomType`: `PRIVATE` (phòng riêng), `SHARED` (ở ghép).
- `workSchedule`: `DAY`, `NIGHT` (lịch học/làm việc).
- `personalValue`: `PRIVACY`, `SCHEDULE`, `CLEAN` (điều trân trọng), tách biệt với trọng số ghép đôi `topPriority`.
- Bốn trường tùy chọn: bản ghi cũ để `NULL` và UI hiển thị chưa chọn, không tự suy đoán lựa chọn. PUT bỏ trường hoặc gửi `null` giữ giá trị đã lưu; chuỗi trống/enum không hợp lệ/ngày không hợp lệ trả `400`, không ghi đè dữ liệu. Response PUT trả giá trị thực tế sau lưu, kể cả giá trị giữ lại từ client cũ. Quyền chủ tài khoản/admin giữ nguyên.
- Flutter gửi các lựa chọn, khôi phục khi mở lại và đưa vào bước tổng kết. Lỗi đọc chặn lưu thay vì ghi đè mặc định; lỗi lưu giữ bản nháp. Chỉ báo thành công khi response xác nhận đầy đủ các trường mới đã gửi. Chưa bổ sung bốn trường vào công thức/chế độ lọc Matching, không hứa tăng độ tương thích từ những trường này.
- Database cũ chạy migration PostgreSQL `database/migrations/20261002_survey_preferences.sql` trước khi khởi động backend mới. Không chạy lại `01_schema.sql`/`02_seed_data.sql`; không có thay đổi seed hay tự sửa dữ liệu cũ.

### 4.2. GET `/matching/recommendations`

Query parameters:

| Tham số | Kiểu | Mặc định | Mô tả |
|---|---|---:|---|
| `page` | integer | `0` | Trang hiện tại |
| `size` | integer | `20` | Số phần tử, tối đa 100 |
| `sort` | string | `matchScore,desc` | `matchScore`, `budgetAmount` hoặc `createdAt` |
| `minScore` | number | `0` | Điểm tương thích tối thiểu 0–100 |

Quy tắc nghiệp vụ:

1. Lấy người dùng hiện tại từ JWT và yêu cầu đã hoàn thành khảo sát.
2. Chỉ lấy ứng viên `ACTIVE` và đang bật trạng thái tìm roommate.
3. Loại chính người dùng hiện tại, người đã chặn/bị chặn và các cặp bị loại theo trạng thái Match Request.
4. Áp dụng tiêu chí bắt buộc trước khi tính điểm.
5. Tính điểm chuẩn hóa 5 chiều với trọng số: ngân sách 30%, giờ ngủ 25%, sạch sẽ 20%, hút thuốc 15%, thú cưng 10%; nếu có priorities thì chuẩn hóa lại tổng trọng số.
6. Điểm nằm trong `[0, 100]`, làm tròn hai chữ số và sắp xếp giảm dần.

Response `200 OK`:

```json
{
  "status": 200,
  "message": "Lấy danh sách gợi ý thành công",
  "data": {
    "items": [
      {
        "userId": 2,
        "fullName": "Văn Nam",
        "avatarUrl": null,
        "targetDistrict": "Thu Duc",
        "budgetAmount": 2100000,
        "bioDescription": "Hòa đồng, thích học nhóm",
        "matchScore": 85.2,
        "criteriaDetail": {
          "budgetMatch": 92.0,
          "sleepMatch": 75.0,
          "cleanlinessMatch": 100.0,
          "smokingMatch": 100.0,
          "petMatch": 100.0
        },
        "matchedReasons": [
          "Cùng không hút thuốc",
          "Mức độ sạch sẽ tương đồng",
          "Ngân sách phù hợp"
        ]
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "sort": "matchScore,desc"
  }
}
```

Lỗi: `401` chưa đăng nhập, `422 PREFERENCES_INCOMPLETE`.

### 4.3. GET `/matching/search`

Query ví dụ:

```http
GET /api/v1/matching/search?district=Thu%20Duc&minBudget=1500000&maxBudget=3000000&minScore=60&page=0&size=20&sort=matchScore,desc
```

| Tham số | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `district` | string | Không | Khu vực mong muốn |
| `minBudget` | integer | Không | Ngân sách thấp nhất |
| `maxBudget` | integer | Không | Ngân sách cao nhất |
| `minScore` | number | Không | Điểm tối thiểu 0–100 |
| `page`, `size`, `sort` | mixed | Không | Phân trang và sắp xếp |

Response dùng cùng `MatchRecommendation` schema với recommendations.

### 4.4. GET `/matching/candidates/{candidateId}`

Trước Double Opt-in, response không chứa `phone` hoặc `email`:

```json
{
  "status": 200,
  "message": "Lấy hồ sơ ứng viên thành công",
  "data": {
    "userId": 2,
    "fullName": "Văn Nam",
    "avatarUrl": null,
    "gender": "MALE",
    "targetDistrict": "Thu Duc",
    "budgetAmount": 2100000,
    "sleepHabit": 1,
    "cleanlinessLevel": 4,
    "isSmoking": false,
    "allowPets": false,
    "bioDescription": "Hòa đồng, thích học nhóm",
    "matchScore": 85.2
  }
}
```

Lỗi: `403 CANDIDATE_BLOCKED_OR_HIDDEN`, `404 CANDIDATE_NOT_FOUND`.

### 4.5. GET `/matching/candidates/{candidateId}/compatibility`

Response `200 OK`:

```json
{
  "status": 200,
  "message": "Phân tích tương thích thành công",
  "data": {
    "candidateId": 2,
    "matchScore": 85.2,
    "criteriaDetail": {
      "budgetMatch": 92.0,
      "sleepMatch": 75.0,
      "cleanlinessMatch": 100.0,
      "smokingMatch": 100.0,
      "petMatch": 100.0
    },
    "matchedReasons": ["Cùng không hút thuốc", "Mức độ sạch sẽ tương đồng"],
    "conflictingReasons": ["Giờ ngủ có khác biệt"],
    "calculatedAt": "2026-09-12T10:30:00Z"
  }
}
```

## 5. Request/Response schema cho các nhóm còn lại

### 5.1. Match Request

Endpoint hiện hành: `POST /api/v1/matches/requests?receiverId=2`, không nhận body.

Server tự tính lại `matchScore`; không tin điểm do client gửi. Response gồm `requestId`, `partnerId`, `partnerName`, `partnerAvatar`, `matchScore`, `status` và `createdAt`. `contactPhone`/`contactEmail` chỉ có giá trị sau khi Double Opt-in thành công.

- Yêu cầu mới trả `PENDING`. Gửi lại cùng chiều sử dụng lời mời hiện có, không tạo thêm dòng.
- Nếu đối phương đã gửi lời mời `PENDING`, thao tác gửi ngược chiều sẽ chấp nhận kết nối và trả `ACCEPTED`. Kết nối đã chấp nhận cũng trả `ACCEPTED` khi gửi lại.
- Flutter dùng trạng thái trả về để phân biệt **đã gửi lời mời** và **đã kết nối**, không suy luận thành công chỉ từ mã HTTP. Điểm hiển thị lấy từ dữ liệu gợi ý hoặc response, không dùng điểm mẫu.
- API chưa hỗ trợ lời nhắn kèm lời mời. Ô nhập trên màn gửi lời mời hiện bị vô hiệu hóa và ghi rõ hạn chế; người dùng có thể chat sau khi kết nối. Không có thay đổi schema cho lần sửa này.

### 5.2. Room Post

```json
{
  "title": "Tìm bạn nam ở ghép gần trường",
  "description": "Phòng 25m2, có gác và máy lạnh",
  "price": 1800000,
  "address": "Linh Trung, TP. Thủ Đức",
  "maxOccupants": 2,
  "imageObjectKey": null
}
```

Trạng thái: `PENDING`, `APPROVED`, `REJECTED`, `AVAILABLE`, `CLOSED`.

- `POST /posts` yêu cầu tiêu đề, mô tả, địa chỉ, giá và sức chứa. `PUT /posts/{id}` vẫn cho cập nhật riêng từng trường: trường bỏ qua hoặc `null` giữ nguyên dữ liệu cũ, nhưng giá trị có cung cấp phải hợp lệ.
- Giá phải hữu hạn và từ 100.000 VNĐ; tiền cọc, tổng điện nước/phí dịch vụ và diện tích phải hữu hạn, không âm. Tiêu đề/địa chỉ/mô tả không được trống khi cung cấp; giới hạn tiêu đề 200, địa chỉ 255, khu vực 100, tiện ích 500 ký tự. Khu vực có thể bỏ qua nhưng không được là chuỗi trống khi cung cấp. Sai dữ liệu trả `400` trước khi đổi nội dung hoặc chuyển tin về `PENDING`.
- API hiện lưu/trả một ảnh phòng (`imageObjectKey` khi tải lên, `imageUrl` khi đọc), chưa hỗ trợ bộ ảnh theo phòng khách/phòng ngủ/bếp. Flutter chỉ hiển thị ảnh này, không giả lập bốn ảnh. Chưa có ảnh thì vô hiệu hóa nút xem ảnh; các đường dẫn ảnh cũ vẫn mở cùng ảnh thực tế.
- Tiện ích, tiền cọc và tổng chi phí hiển thị từ dữ liệu thực tế; dữ liệu thiếu ghi “Chưa cập nhật”. Không tự gán nội thất, cọc một tháng, đơn giá điện/nước, nội quy hoặc mô tả phòng mẫu. Nhóm sửa này không đổi schema và không cần chạy thêm SQL.

### 5.3. Viewing Appointment

```json
{
  "roomPostId": 1,
  "appointmentTime": "2026-09-15T09:00:00Z",
  "note": "Xin xem phòng vào buổi sáng"
}
```

Trạng thái: `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`. Server lấy `requesterId` từ JWT và xác định `hostId` từ bài đăng.

- Endpoint đang triển khai: `POST /appointments`, `GET /appointments/my`, `PUT /appointments/{id}/status?status=CANCELLED` (hoặc `CONFIRMED`/`COMPLETED` cho chủ phòng). `/my` trả lịch mà tài khoản hiện tại là người đặt **hoặc** chủ phòng; Flutter lọc `requesterId` khi hiển thị lịch đã đặt.
- `requesterPhone` và `hostPhone` là các trường nullable. Chỉ trả số điện thoại khi chính người đặt và chủ phòng có kết nối `ACCEPTED` (Double Opt-in), cả hai tài khoản `ACTIVE` và không chặn nhau ở bất kỳ chiều nào. Trạng thái lịch hẹn, kể cả `CONFIRMED`, không tự cấp quyền xem liên hệ; lịch đã hủy/hoàn tất cũng không tự thu hồi một kết nối `ACCEPTED` còn hợp lệ.
- Kiểm tra quyền liên hệ hiện tại ở mọi response tạo lịch, danh sách và cập nhật trạng thái, kể cả gửi lại trạng thái không đổi. Hủy kết nối, chặn nhau hoặc khóa một tài khoản sẽ ẩn cả hai số điện thoại trong response tiếp theo, không xóa lịch sử lịch hẹn. Thay đổi này không cần migration SQL.
- Tạo lịch, xác nhận (`CONFIRMED`) và hoàn tất (`COMPLETED`) đều kiểm tra hai tài khoản `ACTIVE`, không chặn nhau hai chiều và tin phòng còn `APPROVED`/`AVAILABLE`. Tài khoản không hoạt động hoặc chặn nhau trả `403`; tin chưa duyệt/bị từ chối/đã đóng trả `400`, không lưu lịch mới hoặc đổi trạng thái. Token của chính tài khoản bị khóa vẫn bị lớp xác thực từ chối bằng `401`.
- Chỉ chủ phòng được gửi lệnh xác nhận/hoàn tất, kể cả gửi lại `CONFIRMED` khi lịch đã xác nhận; lệnh lặp lại cũng không bỏ qua kiểm tra điều kiện hiện tại. Lịch sử không bị xóa hay tự đổi trạng thái khi chặn/khóa/đóng tin; người tham gia còn đăng nhập hợp lệ vẫn xem và hủy lịch `PENDING`/`CONFIRMED` được. Lịch `CANCELLED`/`COMPLETED` vẫn là trạng thái cuối, không cho thay đổi.
- Cá nhân → **Lịch xem phòng** mở `/viewing-appointments`, không mở màn lời mời ghép đôi. Danh sách, chi tiết và xác nhận đặt lịch dùng ID, ngày giờ, phòng, người đăng, ghi chú và trạng thái API thật; không có lịch mẫu hay số lượng lịch tự gán. Các mục Sắp tới/Lịch sử/Đã hủy được phân loại theo thời gian và trạng thái thực tế; có tải lại, lỗi và thử lại.
- Người đặt chỉ hủy lịch `PENDING`/`CONFIRMED`; không tự xác nhận hoặc hoàn tất. Hủy chỉ cập nhật UI sau response `CANCELLED` đúng lịch/tài khoản; thất bại giữ lịch để thử lại, khóa thao tác khi đang gửi. Không có ô lý do hủy vì API hiện chưa lưu trường này, và không khẳng định gửi push notification khi chưa có hỗ trợ.
- Thông báo lịch dùng metadata vai trò/ID thay vì đoán theo tiêu đề: người đặt mở chi tiết lịch đúng ID; chủ phòng mở yêu cầu tại đúng tin đăng. Chi tiết kiểm tra lịch thuộc người đặt; mở phòng lấy dữ liệu tin hiện tại, tin không còn hiển thị báo lỗi thay vì dựng dữ liệu giả. Nút nhắn người đăng chỉ xuất hiện với lịch đã xác nhận; backend vẫn kiểm tra quyền chat.
- Nhóm sửa này nối giao diện vào API và schema hiện có; không cần migration SQL.

### 5.4. Report

```json
{
  "targetType": "USER",
  "targetId": 3,
  "reason": "Thông tin hồ sơ không trung thực"
}
```

`targetType`: `USER` hoặc `ROOM_POST`. Trạng thái: `PENDING`, `RESOLVED`, `DISMISSED`.

### 5.5. Admin status update

Endpoint hiện hành: `PUT`/`PATCH /admin/users/{userId}/status`, nhận JSON với trạng thái đích bắt buộc. Khóa tài khoản gửi `LOCKED`; mở khóa gửi `ACTIVE`:

```json
{
  "status": "LOCKED"
}
```

Chỉ chấp nhận hai giá trị viết hoa `ACTIVE` và `LOCKED`. Thiếu body/trường, `null`, chuỗi trống hoặc trạng thái khác trả `400`, không đổi tài khoản. Đây là thao tác đặt trạng thái, không đảo trạng thái: gửi lại cùng lệnh hoặc gửi từ màn hình đã cũ vẫn giữ đúng trạng thái đích. Response thành công:

```json
{
  "userId": 12,
  "status": "LOCKED"
}
```

Chỉ admin đang hoạt động được thay đổi trạng thái; user thường nhận `403`, thiếu/không hợp lệ token hoặc admin bị khóa nhận `401`. Tài khoản đích không tồn tại trả `404`. Admin không được cập nhật trạng thái chính tài khoản đang đăng nhập (`403`) với cả lệnh khóa và mở khóa.

Alias cũ `PUT`/`PATCH /admin/users/{userId}/toggle-status` vẫn được định tuyến nhưng cũng yêu cầu cùng JSON trạng thái đích, không còn hành vi toggle hoặc fallback khi thiếu body. Cần cập nhật backend và Flutter cùng nhau: client cũ gửi yêu cầu không body sẽ nhận `400`.

Flutter gửi trạng thái đích qua `/status`, khóa thao tác khi đang chờ và chỉ cập nhật UI/callback khi response xác nhận đúng `userId` và trạng thái đã yêu cầu. Lỗi HTTP hoặc response thiếu/sai thông tin không được coi là thành công; giữ trạng thái hiển thị để thử lại. Cập nhật backend dùng khóa ghi trên dòng tài khoản hiện có, không thay đổi schema.

Hành vi khóa tài khoản (`ACTIVE` → `LOCKED`) trên các endpoint hiện hành:

- Tự khóa tài khoản đang đăng nhập trả `403` và không đổi trạng thái.
- Tin `APPROVED`/`AVAILABLE` của tài khoản bị khóa bị ẩn khỏi danh sách công khai; xem chi tiết và lưu tin mới trả `404`. Admin vẫn xem được tin để kiểm duyệt.
- Tạo lịch hẹn mới với chủ phòng bị khóa trả `403`. Lịch hẹn cũ không bị xóa hay tự đổi trạng thái; người đặt vẫn xem và hủy lịch hẹn theo quyền hiện hành.
- `POST /chat/messages` trả `403` nếu người nhận không `ACTIVE`, kể cả khi đã kết nối hoặc có lịch hẹn `CONFIRMED`. Không lưu tin nhắn bị từ chối. Mở khóa cho phép gửi lại nếu quan hệ kết nối/lịch hẹn và điều kiện chặn vẫn hợp lệ; lịch sử chat, kết nối và lịch hẹn cũ được giữ nguyên.
- `GET /admin/posts` và response kiểm duyệt tin có trường boolean `publiclyVisible`: chỉ `true` khi chủ tin `ACTIVE` và tin `APPROVED`/`AVAILABLE`, cùng điều kiện với danh sách công khai. Admin vẫn nhận tất cả tin để kiểm duyệt, nhưng dashboard chỉ đếm `publiclyVisible == true` cho “Tin đang hiển thị”; số tin chờ duyệt không bị lọc theo trạng thái chủ tin. Cần cập nhật cả backend và Flutter để dùng trường mới.
- Mở khóa hiển thị lại tin đã duyệt/đang mở. Không tự duyệt tin `PENDING` hoặc mở lại tin `CLOSED`, và không xóa dấu lưu tin cũ. Người dùng vẫn có thể bỏ lưu tin đã bị ẩn.
- Đây là thay đổi kiểm tra quyền/khả năng hiển thị ở backend; không cần thay đổi schema hoặc chạy thêm SQL.

### 5.6. Thông tin hồ sơ trong trang quản lý tài khoản

`GET /admin/users` và `GET /admin/users/{userId}` trả `UserResponseDTO`, gồm thông tin hồ sơ hiện có (`phone`, `gender`, `university`, `birthDate`, `avatarUrl`) và `createdAt` từ thời điểm tạo tài khoản trong database. Các trường tùy chọn chưa cập nhật giữ nguyên `null`; không trả mật khẩu hoặc refresh token.

Frontend giữ các trường này khi chuyển từ danh sách sang chi tiết admin. Thông tin liên hệ trống/chuỗi trắng hiển thị “Chưa cập nhật”, không thay bằng số điện thoại/email mẫu. Trang admin không khẳng định email đã xác minh khi API chưa cung cấp trạng thái xác minh.

Hồ sơ công khai vẫn dùng DTO riêng, không mở thêm quyền xem liên hệ, ngày sinh hoặc ngày tạo tài khoản. `createdAt` đã có trong bảng `users`, nên nhóm sửa này không yêu cầu migration SQL.

- `GET /profile/public/{userId}` yêu cầu người xem đăng nhập bằng tài khoản `ACTIVE`. Nếu người xem và đối tượng chặn nhau ở bất kỳ chiều nào, trả `403` không kèm dữ liệu hồ sơ, kể cả đã kết nối `ACCEPTED`. Admin không vượt điều kiện chặn trên endpoint công khai; API chi tiết admin vẫn giữ quyền quản trị hiện có.
- Hồ sơ không tồn tại, tài khoản đích bị khóa hoặc đã tắt tìm bạn vẫn trả `404`. Bỏ chặn chỉ khôi phục truy cập khi không còn chặn ở cả hai chiều và hồ sơ vẫn công khai; chặn một người khác không ảnh hưởng quyền xem hồ sơ này. Thay đổi dùng bảng chặn hiện có, không cần SQL mới.

#### Chỉnh sửa hồ sơ cá nhân — giới thiệu và ngày sinh

- Endpoint đang triển khai: `PUT /profile/user/{userId}`, query parameters `fullName`, `phone`, `gender`, và các trường tùy chọn `birthDate` (ISO date), `university`, `bioNote`. Chỉ chủ tài khoản hoặc admin có quyền cập nhật; response thành công là `UserResponseDTO`.
- Không truyền `birthDate` thì giữ nguyên ngày sinh hiện có, kể cả `null`. Flutter không tự gán ngày sinh mẫu khi chỉ sửa tên/trường học/giới thiệu.
- `bioNote` là phần giới thiệu tự do trong `user_preferences.bio_description`, không phải toàn bộ nội dung khảo sát. Không truyền thì giữ nguyên; chuỗi trống xóa riêng phần giới thiệu, giữ nguyên dòng metadata khảo sát và tất cả cột tiêu chí. Thông tin tài khoản và giới thiệu được lưu trong cùng transaction sau khi kiểm tra đầu vào.
- Chưa có tiêu chí: vẫn sửa thông tin tài khoản được, nhưng cần hoàn thành khảo sát trước khi thêm giới thiệu; backend trả `400` nếu gửi giới thiệu không trống, không tự tạo tiêu chí giả. Lỗi tải giới thiệu chặn nút lưu và cho thử lại; lỗi lưu giữ bản nháp. Sau khi lưu, màn hồ sơ cập nhật thông tin và tải lại tiêu chí.
- Dùng cấu trúc database hiện có, không thêm migration SQL cho nhóm sửa này.

### 5.7. Trạng thái tải kết nối và lịch sử chat

- Màn kết nối chỉ hiển thị dữ liệu sau khi cả danh sách đã nhận và đã gửi tải thành công. Lỗi mạng, HTTP hoặc dữ liệu không hợp lệ hiển thị lỗi và nút “Thử lại”, không bị coi là danh sách trống. Có thể kéo để tải lại cả khi danh sách thực sự trống.
- Chat dùng các endpoint hiện hành `GET /chat/messages/{partnerId}` và `POST /chat/messages`. Lỗi tải lần đầu hiển thị lỗi thay vì lời chào cho cuộc trò chuyện trống. Nếu cập nhật định kỳ thất bại, giữ lịch sử đã tải và hiển thị cảnh báo; cập nhật thành công xóa cảnh báo. Không chạy các lượt tải lịch sử chồng nhau.
- Chỉ xóa nội dung/ảnh đang soạn khi API xác nhận gửi thành công; gửi thất bại giữ bản nháp để thử lại. Giao diện không tự khẳng định người nhận “trực tuyến” khi chưa có dữ liệu trạng thái online từ backend.
- Nhóm sửa này chỉ đổi trạng thái và xử lý lỗi ở Flutter, không thêm bảng/cột hay yêu cầu migration SQL.

### 5.8. Ảnh riêng tư trên R2 — chat và minh chứng báo cáo

- `POST /uploads/presign` nhận purpose `avatar`, `room-post`, `chat` hoặc `report`. Avatar/ảnh phòng dùng `R2_BUCKET_NAME` công khai và có `publicUrl`. Chat/báo cáo dùng bucket **khác** `R2_PRIVATE_BUCKET_NAME`, trả `publicUrl: null`; không được bật `r2.dev` hoặc custom domain công khai cho bucket private. Secret chỉ ở backend; quyền object của token được giới hạn trên hai bucket này.
- Flutter upload bằng `uploadUrl` (PUT), kèm `Content-Type`, `Content-Length` và riêng chat/report có `Cache-Control: private, no-store` đã ký để lưu metadata chống cache trên object. CORS bucket phải cho phép các header này. Sau đó chat gửi `imageObjectKey` qua `POST /chat/messages`; báo cáo tiếp tục gửi `evidenceObjectKey`. Key phải đúng người upload, đúng purpose và đúng dạng `<directory>/<userId>/<UUID>.<jpg|png|webp>`. Key sai trả `403`, purpose không hợp lệ trả `400`; request bị từ chối không tạo tin nhắn/báo cáo. Mọi `imageUrl` cũ không trống trong request chat đều trả `400`, kể cả URL từng được coi là tin cậy; không còn tính năng dán URL ảnh chat.
- Database dùng cột `chat_messages.image_url` và `reports.evidence_url` hiện có để lưu **key**, không lưu signed URL. Không thêm bảng/cột và không có migration SQL trong nhóm sửa này.
- Response chat vẫn có `imageUrl`, nhưng chỉ là signed GET URL: cấp cho đúng hai người trong cuộc trò chuyện, cả hai `ACTIVE` và không chặn nhau ở bất kỳ chiều nào. Admin/người ngoài không có quyền xem ảnh chat người khác. Hủy kết nối không xóa lịch sử; quyền gửi tin vẫn cần kết nối `ACCEPTED` hoặc lịch hẹn `CONFIRMED`. Chặn/khóa giữ lịch sử chữ nhưng ngừng cấp URL ảnh mới; bỏ chặn/mở khóa chỉ khôi phục nếu mọi điều kiện còn hợp lệ.
- `GET /admin/reports` và response xử lý báo cáo đều trả `evidenceUrl` dạng signed GET chỉ cho admin `ACTIVE`. Người thường nhận `403`, token thiếu/không hợp lệ hoặc admin bị khóa nhận `401`. Reporter bị khóa không làm mất quyền xem minh chứng của admin.
- Signed GET mặc định 2 phút, cấu hình `R2_PRIVATE_READ_DURATION_MINUTES` bị giới hạn 1–5 phút. Presign/chat/báo cáo admin dùng HTTP `Cache-Control: no-store`, object GET có `private, no-store`. Signed URL là bearer URL: ai đã có link vẫn có thể dùng đến hết hạn; chặn/khóa không thu hồi ngay link đã cấp và không thu hồi bản đã tải. URL hết hạn cần tải lại dữ liệu để được kiểm tra quyền và cấp link mới. Xem [Cloudflare presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/).
- Thiếu/bucket private không hợp lệ hoặc trùng public trả `503` cho upload/ghi ảnh private; không fallback sang public. Nếu `R2_ENABLED=false`, endpoint upload không được đăng ký; gửi key ảnh chat/báo cáo trả `503`. Chat chữ/báo cáo không ảnh vẫn hoạt động. Khi private storage chưa cấu hình, lịch sử chat/dữ liệu báo cáo vẫn trả được nhưng trường ảnh là `null`.
- Legacy URL public hoặc key sai cấu trúc trong lịch sử trả ảnh `null`, không lộ URL/key qua mapper DTO. **Object đã upload public trước đây không tự trở thành riêng tư**: cần xử lý/migrate/gỡ bản public cũ trên R2 riêng và cập nhật tham chiếu; bản cập nhật không tự sửa DB hay dữ liệu R2 cũ. Bucket public thật sự phải được kiểm tra trên Cloudflare; backend không thể xác minh quyền public của bucket chỉ bằng presigning offline.
- Cập nhật backend và Flutter cùng nhau, thêm cấu hình bucket private rồi khởi động/build lại. Flutter giữ ảnh preview/nội dung/key sau lỗi gửi để thử lại không upload trùng; lỗi upload giữ bản nháp và không chuyển sang dán URL công khai.
- Màn báo cáo admin làm mới dữ liệu khi chọn/chọn lại báo cáo; có nút làm mới/thử lại ảnh khi hết hạn hoặc lỗi. Trong lúc làm mới hoặc khi lỗi, không dùng URL cũ; giữ lựa chọn theo ID và bản nháp ghi chú, bỏ response đến trễ. Không dùng `imageUrl` legacy thay cho `evidenceUrl` bị thiếu, và không hiển thị URL public/không hợp lệ như minh chứng private.
- Chat polling giữ cùng signed URL cho cùng message/người gửi/người nhận/host/path khi còn hơn 30 giây và thời hạn ký nằm trong 60–300 giây, để tránh tải lại cùng ảnh mỗi 3 giây. Các trường nội dung/trạng thái vẫn lấy response mới. Server trả ảnh `null` thì xóa URL ngay; ảnh thay đổi hoặc link gần hết hạn dùng URL mới, không tái dùng link public/legacy để giữ ảnh.

### 5.9. Bộ lọc phòng và tải lại tiêu chí trên hồ sơ

- Bộ lọc phòng mặc định và “Xóa bộ lọc” dùng giá tối thiểu 0, không giới hạn giá tối đa, tất cả khu vực/diện tích và không chọn tiện ích. Không khôi phục bộ lọc demo; phòng dưới 1 triệu hoặc trên 15 triệu vẫn xuất hiện khi không có điều kiện lọc khác.
- Mở rồi áp dụng bộ lọc không tự nâng giá tối thiểu hay hạ giá tối đa đã chọn. Giá không giới hạn được biểu diễn riêng trong trạng thái Flutter, không gửi `Infinity` qua API; thanh trượt dùng giá trị hữu hạn và hiển thị rõ lựa chọn không giới hạn. Hủy màn bộ lọc không áp dụng bản nháp. Tắt lọc nhanh giá hoặc “Xem tất cả phòng” cũng bỏ trần giá mặc định.
- Sau khi khảo sát lưu thành công và trả `true`, màn hồ sơ tải lại `GET /profile/preferences/{userId}` để hiển thị tiêu chí mới. Quay lại/hủy hoặc lưu thất bại không báo cập nhật thành công. Khi tải hoặc lỗi, hiển thị trạng thái tương ứng và cho thử lại; chỉ response thành công không có tiêu chí mới được coi là chưa thiết lập. Response cũ đến trễ không ghi đè lượt tải mới.
- Nhóm sửa này chỉ thay đổi Flutter và kiểm thử, không đổi endpoint/backend/schema và không cần chạy SQL trên Supabase.

### 5.10. Chuẩn hóa lỗi nghiệp vụ và hồi quy

- Không tìm thấy tài nguyên trả `404`, gồm duyệt tin không tồn tại, tài khoản/báo cáo/lịch không tồn tại hoặc người dùng không tồn tại khi lưu tiêu chí. Chưa thiết lập tiêu chí vẫn có thể trả kết quả rỗng theo luồng hiện có. Sai ID/số/boolean/ngày, thiếu tham số, JSON sai hoặc validation thất bại trả `400`; không đi vào thao tác ghi.
- Tự đặt lịch phòng của mình, thời gian hẹn null/quá khứ, tự gửi tin hoặc tự gửi lời mời trả `400`. Vi phạm quyền/chặn/khóa tiếp tục trả `403`; thiếu/hết hiệu lực xác thực giữ `401`, không hạ thành lỗi validation. Không thay đổi quy tắc liên hệ, lịch hẹn hay ảnh private của các nhóm trước.
- Đăng ký email đã tồn tại trả `409`; đổi mật khẩu với mật khẩu hiện tại sai trả `400`, không thay đổi mật khẩu hoặc thu hồi phiên. Lỗi lưu/đọc do dịch vụ chưa sẵn sàng giữ mã `503` đã chỉ định, không đổi thành `400`.
- Tạo/sửa tin với `imageObjectKey` không trống nhưng R2 chưa cấu hình trả `503`. Sửa tin kiểm tra ảnh trước khi đổi nội dung/trạng thái; không bỏ qua ảnh rồi báo thành công. Tin không yêu cầu ảnh vẫn dùng luồng hiện có.
- MVC giữ `404` cho route không tồn tại, `405` cùng header `Allow` cho method không hỗ trợ, `415` cho Content-Type không phù hợp. `RuntimeException`/exception ngoài dự kiến vẫn trả `500` với thông báo chung “Đã xảy ra lỗi máy chủ”; chi tiết chỉ ghi log server, không trả exception, SQL hay thông tin cấu hình nội bộ cho client.
- Flutter giữ mã HTTP/thông báo lỗi; các lỗi `400/403/404/409/500/503` không tự làm mất phiên, không cập nhật trạng thái hoặc mở màn thành công khi request thất bại. `401` vẫn xử lý refresh token/hết phiên theo cơ chế hiện có.
- Không thêm bảng/cột, migration, dependency hoặc cấu hình Supabase trong nhóm này. Cần khởi động lại backend để áp dụng; kiểm thử tự động dùng H2/mock, không thay thế kiểm thử thiết bị và dịch vụ thật.

## 6. Sự kiện tự động và quyền riêng tư

- Gửi Match Request: tạo thông báo cho người nhận.
- Accept/Reject: tạo thông báo cho người gửi.
- Double Opt-in thành công: tạo hai bản ghi `contact_permissions`, mở liên hệ cho đúng hai người và tạo thông báo cho cả hai.
- Block: hai người không còn xuất hiện trong kết quả tìm kiếm/gợi ý của nhau và không thể tạo Match Request mới.
- `GET /blocks` và `POST /blocks` chỉ trả `id`, `blockedUserId`, `blockedUserName`, `blockedUserAvatar`, `createdAt`; không trả email, số điện thoại hoặc dữ liệu xác thực, kể cả khi hai người từng kết nối.
- Hủy kết nối không xóa lịch sử audit; thông tin liên hệ bị khóa lại.
- API hồ sơ/matching tuyệt đối không trả `passwordHash`, refresh token hoặc thông tin liên hệ chưa được cấp quyền.

## 7. Quy ước mã lỗi nghiệp vụ

| Code | HTTP | Ý nghĩa |
|---|---:|---|
| `VALIDATION_ERROR` | 400 | Một hoặc nhiều trường không hợp lệ |
| `INVALID_CREDENTIALS` | 401 | Sai email hoặc mật khẩu |
| `TOKEN_INVALID` | 401 | Access token không hợp lệ |
| `TOKEN_EXPIRED` | 401 | Access token hết hạn |
| `FORBIDDEN` | 403 | Không có quyền thực hiện |
| `EMAIL_ALREADY_EXISTS` | 409 | Email đã được đăng ký |
| `PREFERENCES_INCOMPLETE` | 422 | Chưa đủ tiêu chí để Matching |
| `MATCH_REQUEST_ALREADY_EXISTS` | 409 | Yêu cầu giữa hai người đã tồn tại |
| `SELF_MATCH_NOT_ALLOWED` | 400 | Gửi yêu cầu cho chính mình |
| `MATCH_REQUEST_NOT_PENDING` | 409 | Yêu cầu không còn ở trạng thái chờ |
| `CONTACT_NOT_UNLOCKED` | 403 | Chưa hoàn tất Double Opt-in |
| `RESOURCE_NOT_FOUND` | 404 | Không tìm thấy tài nguyên |
| `ACCOUNT_LOCKED` | 403 | Tài khoản đã bị khóa |

## 8. Checklist nghiệm thu API Contract

- [x] Có trên 25 endpoint (hiện tại: 48).
- [x] Có Generic API Response và Error Response thống nhất.
- [x] Có quy ước `400`, `401`, `403`, `404`, `409`.
- [x] Auth request/response được mô tả chi tiết.
- [x] Matching request/response, bộ lọc, thuật toán và quyền riêng tư được mô tả chi tiết.
- [x] Endpoint được đối chiếu với FR-01 đến FR-38.
- [x] Người dùng hiện tại được xác định từ JWT, tránh giả mạo `userId`.
- [x] Không trả thông tin liên hệ trước Double Opt-in.
