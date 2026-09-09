# HƯỚNG DẪN LÀM VIỆC VỚI GIT & GITHUB DÀNH CHO NHÓM (GIT WORKFLOW)

> **Mục đích**: Giúp 3 thành viên (**Quốc Huy, Quang Huy, Tiến Đạt**) phối hợp lập trình trơn tru, không bao giờ bị mất code và biết cách giải quyết xung đột (Merge Conflict) dễ dàng như chuyên nghiệp.

---

## 🛑 NGUYÊN TẮC VÀNG: TẠI SAO XUNG ĐỘT (CONFLICT) XẢY RA?

Xung đột xảy ra khi **2 người cùng sửa vào cùng một dòng code trong cùng một file** và cùng đẩy lên GitHub. Khi đó Git không biết phải chọn code của ai và sẽ báo lỗi: `CONFLICT (content): Merge conflict in...`.

### 3 "Điều cấm kỵ" để 95% không bao giờ bị xung đột:
1. **KHÔNG BAO GIỜ code trực tiếp trên nhánh `master`**: Nhánh `master` chỉ dùng để chứa sản phẩm ổn định cuối cùng. Mỗi bạn làm việc trên một nhánh riêng (Branch).
2. **LUÔN LUÔN kéo code mới về trước khi bắt đầu làm**: Đầu buổi làm việc, luôn chạy `git pull` để nhận code mới nhất mà bạn khác đã đẩy lên.
3. **Mỗi người phụ trách file/module riêng**: Ví dụ Quang Huy code `AuthController.java`, Quốc Huy code `ProfileController.java`, Tiến Đạt code `RoomPostController.java`. Không cùng nhảy vào sửa 1 file cùng một lúc.

---

## 🚀 QUY TRÌNH LÀM VIỆC 5 BƯỚC HÀNG NGÀY (DAILY WORKFLOW)

Mỗi khi bắt đầu làm một công việc mới, hãy làm đúng 5 bước sau:

### Bước 1: Cập nhật code mới nhất từ GitHub
Mở Terminal tại thư mục dự án và chạy:
```bash
# 1. Chuyển về nhánh chính
git checkout master

# 2. Kéo toàn bộ code mới nhất về máy
git pull origin master
```

### Bước 2: Tạo một nhánh riêng cho tính năng bạn sắp làm
Đặt tên nhánh theo cú pháp: `feature/<tên-tính-năng>-<tên-bạn>`
```bash
# Ví dụ Quốc Huy làm tính năng khảo sát tiêu chí:
git checkout -b feature/survey-quochuy

# Ví dụ Quang Huy làm tính năng đăng nhập/JWT:
git checkout -b feature/auth-quanghuy

# Ví dụ Tiến Đạt làm tính năng bài đăng phòng trọ:
git checkout -b feature/roompost-tiendat
```
*(Lệnh `checkout -b` nghĩa là: Tạo nhánh mới và nhảy sang nhánh đó làm việc ngay lập tức).*

### Bước 3: Viết code và kiểm tra chạy thử
- Mở VS Code / Android Studio và viết code cho tính năng của bạn.
- Chạy thử trên máy xem code có lỗi không.

### Bước 4: Lưu lại công việc vào Git (Commit)
Sau khi tính năng đã chạy tốt:
```bash
# 1. Xem lại những file bạn vừa thay đổi
git status

# 2. Chọn tất cả các file đã sửa
git add .

# 3. Lưu lại với thông điệp rõ ràng
git commit -m "feat(backend): hoàn thành API khảo sát lối sống 5 chiều"
```

### Bước 5: Đẩy nhánh của bạn lên GitHub
```bash
# Đẩy nhánh của bạn lên GitHub (thay tên nhánh của bạn vào)
git push origin feature/survey-quochuy
```

---

## 🔀 CÁCH GỘP CODE VÀO NHÁNH CHÍNH (MERGE VÀO MASTER)

Sau khi đã đẩy nhánh của bạn lên GitHub thành công, làm thế nào để gộp vào `master` cho cả nhóm cùng dùng?

### Cách 1: Tạo Pull Request (PR) trên web GitHub (KHUYẾN NGHỊ - CÁCH CHUYÊN NGHIỆP NHẤT)
1. Mở trình duyệt vào link GitHub: `https://github.com/PHamHuy-23/Roomate-and-matching-app`
2. Bạn sẽ thấy một nút màu vàng nổi bật: **Compare & pull request** $\rightarrow$ Bấm vào nút đó.
3. Điền mô tả ngắn gọn: *"Đã hoàn thành xong API khảo sát tiêu chí"*.
4. Bấm **Create pull request**.
5. Nhờ bạn trong nhóm hoặc PM Leader kiểm tra và bấm **Merge pull request** $\rightarrow$ **Confirm merge**.
6. Xong! Code đã được gộp an toàn vào nhánh `master`.

### Cách 2: Gộp trực tiếp bằng lệnh (Nếu muốn nhanh tại máy)
```bash
# 1. Chuyển về nhánh master
git checkout master

# 2. Kéo code master mới nhất về
git pull origin master

# 3. Gộp nhánh tính năng của bạn vào master
git merge feature/survey-quochuy

# 4. Đẩy master đã gộp lên GitHub
git push origin master
```

---

## 🛠️ HƯỚNG DẪN XỬ LÝ KHI BỊ XUNG ĐỘT (MERGE CONFLICT)

Nếu vô tình cả 2 bạn cùng sửa vào một file và khi gộp code Git báo:
```text
CONFLICT (content): Merge conflict in backend/src/main/.../UserService.java
Automatic merge failed; fix conflicts and then commit the result.
```

**ĐỪNG HOẢNG SỢ! Hãy bình tĩnh xử lý theo 4 bước sau:**

### Bước 1: Mở file bị lỗi trên VS Code
Trong VS Code, file bị conflict sẽ hiện chữ **`C`** màu đỏ hoặc cam. Mở file đó ra, bạn sẽ thấy các đoạn code bị xung đột trông như thế này:

```java
<<<<<<< HEAD (Current Change - Code hiện tại của bạn)
    public Double calculateBudget() {
        return budget * 1.1;
    }
=======
    public Double calculateBudget() {
        return budget * 1.2;
    }
>>>>>>> feature/xxx (Incoming Change - Code của bạn kia)
```

### Bước 2: Dùng giao diện thông minh của VS Code để chọn
Ngay phía trên đoạn code đó, VS Code hiển thị 4 nút bấm rất tiện lợi:
- **`Accept Current Change`**: Giữ code của bạn, bỏ code của bạn kia.
- **`Accept Incoming Change`**: Giữ code của bạn kia, bỏ code của bạn.
- **`Accept Both Changes`**: Giữ cả 2 đoạn code.
- Hoặc bạn có thể **tự tay xóa** các dòng rác `<<<<<<<`, `=======`, `>>>>>>>` và sửa lại dòng code cho hợp lý nhất theo ý cả 2 bạn.

### Bước 3: Lưu file và kiểm tra lại
- Nhấn `Ctrl + S` để lưu file vừa giải quyết conflict.
- Chạy thử chương trình xem có biên dịch được không.

### Bước 4: Hoàn tất việc gộp code
Chạy các lệnh sau trong Terminal:
```bash
# 1. Đánh dấu đã sửa xong conflict
git add .

# 2. Commit xác nhận đã giải quyết xong conflict
git commit -m "fix(conflict): đã giải quyết xung đột merge trong UserService"

# 3. Đẩy lên GitHub
git push origin master
```

---

## 🆘 BẢNG CỨU NGUY CÁC TRƯỜNG HỢP KHẨN CẤP (CHEATSHEET)

| Trường hợp gặp phải | Cách giải quyết nhanh bằng lệnh |
| :--- | :--- |
| **"Tôi lỡ sửa linh tinh và muốn xóa hết quay lại như lúc đầu"** | `git restore .` *(khôi phục toàn bộ file chưa commit về trạng thái sạch)* |
| **"Tôi muốn biết mình đang đứng ở nhánh nào"** | `git branch` *(nhánh có dấu sao `*` là nhánh bạn đang đứng)* |
| **"Tôi muốn chuyển sang nhánh khác"** | `git checkout <tên-nhánh>` |
| **"Tôi muốn xem lịch sử các commit gần nhất"** | `git log --oneline -n 5` |
| **"Git báo không cho push vì trên mạng có code mới hơn"** | Chạy `git pull origin <tên-nhánh>` trước, sau đó mới chạy `git push` |
| **"Tôi muốn hủy bỏ lần merge đang bị conflict dở dang"** | `git merge --abort` *(đưa mọi thứ quay lại lúc trước khi merge)* |

---

> 💡 **Lời khuyên từ PM Leader**: Bất cứ khi nào gặp lỗi lạ về Git mà không chắc chắn, **đừng xóa thư mục dự án**, hãy nhắn ngay cho PM Leader để được hỗ trợ gỡ lỗi từng bước mà không lo mất code!
