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
  "errors": [
    {
      "field": "email",
      "code": "INVALID_EMAIL",
      "message": "Email không đúng định dạng"
    }
  ],
  "timestamp": "2026-09-12T10:30:00Z",
  "path": "/api/v1/auth/register"
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

Tạo yêu cầu:

```json
{
  "receiverId": 2
}
```

Server tự tính lại `matchScore`; không tin điểm do client gửi. Response gồm `requestId`, thông tin partner, `matchScore`, `status` và `createdAt`. `phone`/`email` chỉ xuất hiện sau khi Double Opt-in thành công.

### 5.2. Room Post

```json
{
  "title": "Tìm bạn nam ở ghép gần trường",
  "description": "Phòng 25m2, có gác và máy lạnh",
  "price": 1800000,
  "address": "Linh Trung, TP. Thủ Đức",
  "maxOccupants": 2,
  "imageUrls": []
}
```

Trạng thái: `PENDING`, `APPROVED`, `REJECTED`, `AVAILABLE`, `CLOSED`.

### 5.3. Viewing Appointment

```json
{
  "roomPostId": 1,
  "appointmentTime": "2026-09-15T09:00:00Z",
  "note": "Xin xem phòng vào buổi sáng"
}
```

Trạng thái: `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`. Server lấy `requesterId` từ JWT và xác định `hostId` từ bài đăng.

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

```json
{
  "status": "LOCKED",
  "reason": "Vi phạm tiêu chuẩn cộng đồng"
}
```

Admin không được khóa chính tài khoản đang đăng nhập.

## 6. Sự kiện tự động và quyền riêng tư

- Gửi Match Request: tạo thông báo cho người nhận.
- Accept/Reject: tạo thông báo cho người gửi.
- Double Opt-in thành công: tạo hai bản ghi `contact_permissions`, mở liên hệ cho đúng hai người và tạo thông báo cho cả hai.
- Block: hai người không còn xuất hiện trong kết quả tìm kiếm/gợi ý của nhau và không thể tạo Match Request mới.
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
| `SELF_MATCH_NOT_ALLOWED` | 422 | Gửi yêu cầu cho chính mình |
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
