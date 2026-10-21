# HƯỚNG DẪN CHẠY: TOPIC 3 - THANH TOÁN REST API (MOCK GATEWAY)

---

## 1. Cách Chạy Nhanh

### Bước 1: Bật Server Backend
Mở Terminal gõ:
```bash
cd "Topic Lab/Payment/server"
dart run bin/server.dart
```
> Server chạy tại `http://localhost:8080` (hoặc `http://10.0.2.2:8080` trên máy ảo Android).

### Bước 2: Bật App Flutter
- **Cách 1 (Android Studio)**: Chọn `File ➔ Open` ➔ Mở thư mục `Topic Lab/Payment/app` ➔ Bấm nút **Run ▶**.
- **Cách 2 (Terminal)**:
```bash
cd "Topic Lab/Payment/app"
flutter run
```

---

## 2. Các Tính Năng Đã Hoàn Thiện

1. **Tạo đơn & Ký số HMAC-SHA256**: App tự động ký dữ liệu với secret key để chống sửa trộm số tiền.
2. **Xác thực chữ ký trên Server**: Server kiểm tra chữ ký, từ chối `401 INVALID_SIGNATURE` nếu dữ liệu bị giả mạo.
3. **Mã VietQR (Napas 24/7)**: Màn hình hiển thị mã QR chuẩn ngân hàng (MBBank, STK, số tiền và mã đơn). Có thể quét bằng app ngân hàng thật.
4. **Nút "Đổi STK"**: Tùy chỉnh ngân hàng (MB, VCB, ACB, TPB...), STK và tên chủ tài khoản trực tiếp trên app.
5. **Cơ chế Polling tự động**: App tự động kiểm tra trạng thái mỗi `2 giây` và hủy Timer khi thoát màn hình (chống leak RAM).
6. **Nút test trực tiếp**: Có 2 nút **[Thành công]** và **[Thất bại]** để đổi trạng thái đơn hàng ngay trên app mà không cần gõ lệnh cURL.

---

## 3. Kịch Bản Kiểm Thử

1. Bấm **"Thanh toán ngay"** trên màn hình đơn hàng.
2. App chuyển sang màn hình chờ thanh toán (hiển thị mã VietQR và mã giao dịch).
3. Bấm nút **[Thành công]** ➔ App cập nhật trạng thái `SUCCESS` và chuyển sang màn hình xanh.
4. Bấm **"Quay lại"** ➔ App trở về màn hình ban đầu, Timer tự động dừng.
