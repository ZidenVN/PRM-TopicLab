# BÁO CÁO DỰ ÁN: TOPIC 2 - BẢN ĐỒ & ĐỊNH VỊ GPS (FLUTTER)
> **Chủ đề (Topic 2):** Bản đồ số, Định vị GPS, Dẫn đường OSRM & Mô phỏng theo dõi thời gian thực (Flutter Map, OpenStreetMap & OSRM Engine)  
> **Tài liệu kỹ thuật chi tiết:** Vui lòng xem [HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)

---

## 1. Giới thiệu dự án
Ứng dụng được xây dựng trên nền tảng **Flutter** nhằm giải quyết trọn vẹn 3 yêu cầu cốt lõi của bài thực hành Topic 2:
1. **Question 1 (Bản đồ nền, Vị trí & Phím điều khiển Zoom):**
   - Tích hợp `flutter_map: ^8.3.2` kết nối máy chủ OpenStreetMap Mirror tốc độ cao.
   - Hỗ trợ bộ phím điều khiển Zoom chuyên dụng: Phóng to (+), Thu nhỏ (-), Căn trọn vẹn tuyến đường (Fit Route), và Bay về điểm xuất phát (My Location).
   - Cho phép tùy chọn Điểm xuất phát (A) và Điểm đến (B) linh hoạt bằng chạm map hoặc tìm kiếm địa chỉ. Có nút hoán đổi 2 chiều tức thì (A ⇄ B).
2. **Question 2 (Tính tuyến đường ô tô, Khoảng cách & ETA):**
   - Kết nối máy chủ OSRM Route Engine API để tìm lộ trình ô tô thực tế.
   - Vẽ dải đường Polyline màu xanh uốn lượn men theo các tuyến phố giao thông.
   - Tự động quy đổi đơn vị: mét sang **km**, giây sang **phút / giờ**, và tính **giờ đến dự kiến (ETA)** theo thời gian thực.
   - Có cơ chế Fallback tính khoảng cách tự động đảm bảo app hoạt động ổn định không bao giờ crash khi mạng chập chờn.
3. **Question 3 (Mô phỏng xe chạy thời gian thực - GPS Tracking):**
   - Lắng nghe nhịp di chuyển và cập nhật vị trí xe ô tô lăn bánh từng bước dọc theo tuyến đường OSRM.
   - Camera bản đồ tự động lia bám theo xe (Auto-follow).
   - Tự động giải phóng bộ nhớ (hủy Timer) khi đến nơi hoặc khi người dùng bấm dừng, chống rò rỉ bộ nhớ (memory leak).

---

## 2. Cấu trúc thư mục dự án

```
Map/
├── pubspec.yaml                          # Khai báo dependency (flutter_map, latlong2, http)
├── HUONG_DAN_CHAY.md                     # Báo cáo kỹ thuật chi tiết và kịch bản chấm bài
├── README.md                             # Tài liệu tổng quan dự án
├── lib/
│   ├── main.dart                         # Điểm khởi chạy ứng dụng
│   ├── models/
│   │   └── location_model.dart        # Model LocationModel và TripRoute (tính km, phút, ETA)
│   ├── services/
│   │   └── map_service.dart           # Giao tiếp API Nominatim (tìm kiếm) & OSRM (tính đường)
│   └── screens/
│       └── map_screen.dart            # Màn hình bản đồ tương tác, phím Zoom, xe chạy thời gian thực
└── test/
    └── widget_test.dart                  # Bộ kiểm thử tự động toàn diện (5/5 unit tests passed)
```

---

## 3. Hướng dẫn cài đặt và khởi chạy

### Bước 1: Tải các gói thư viện
Tại thư mục `Topic Lab/Map`:
```bash
flutter pub get
```

### Bước 2: Khởi chạy ứng dụng
Chạy ứng dụng trên thiết bị giả lập Android hoặc Windows Desktop:
```bash
flutter run
```
*(Hoặc mở thư mục `Topic Lab/Map` trong Android Studio và bấm nút Run ▶️)*

### Bước 3: Chạy bộ kiểm thử tự động
```bash
flutter test
```

---

## 4. Tài liệu chi tiết
Để xem phân tích kỹ thuật chuyên sâu, nguyên lý hệ tọa độ Slippy Map, cơ chế lưu cache ảnh bản đồ, thuật toán dự phòng Fallback và kịch bản chấm bài chi tiết từng bước dành cho Giảng viên, vui lòng tham khảo:  
👉 **[HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)**
