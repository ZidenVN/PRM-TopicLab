# BÁO CÁO DỰ ÁN: TOPIC 1 - DATABASE LAB (FLUTTER)
> **Chủ đề (Topic 1):** Cơ sở dữ liệu Offline-First (Local Drift SQLite & Cloud Firebase Firestore)  
> **Tài liệu kỹ thuật chi tiết:** Vui lòng xem [HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)

---

## 1. Giới thiệu dự án
Ứng dụng được xây dựng trên nền tảng **Flutter** nhằm giải quyết toàn diện bài thực hành **Topic 1: Database**:
1. **Local Database (Drift SQLite ORM):**
   - Quản lý cơ sở dữ liệu SQLite cục bộ, hỗ trợ lưu trữ dữ liệu an toàn trên thiết bị ngay cả khi không có kết nối mạng.
   - Ứng dụng mô hình luồng phản ứng theo thời gian thực (**Reactive Stream**) qua `watchMessages()`. Giao diện tự động render lại khi dữ liệu trong database thay đổi.
   - Cung cấp đầy đủ trọn bộ tính năng **CRUD (Create - Read - Update - Delete)**.
2. **Cloud Database (Firebase Cloud Firestore):**
   - Tích hợp trực tiếp với dịch vụ đám mây thời gian thực của Google (Project: `topic-db`).
   - Tự động đồng bộ các bản ghi từ SQLite lên Firestore khi có kết nối Internet và cập nhật trạng thái `isSynced`.
   - **Link xem trực tiếp dữ liệu Cloud qua REST API (không cần tài khoản):**  
     👉 [https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages](https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages)
3. **Cơ chế Khả dụng cao (Fault-Tolerance / Offline-First):**
   - Khi thiết bị mất mạng hoặc chưa có kết nối đám mây, ứng dụng **hoạt động bình thường không bao giờ crash**, lưu dữ liệu vào SQLite và gắn nhãn *"Chỉ có ở local"*.
   - Cho phép người dùng bấm nút 🔄 để đồng bộ lại các bản ghi ngoại tuyến khi có mạng trở lại.

---

## 2. Cấu trúc thư mục dự án

```
DB/
├── pubspec.yaml                          # Khai báo dependency (drift, firebase_core, cloud_firestore)
├── firebase-config.json                  # Cấu hình khóa API kết nối Firebase project topic-db
├── HUONG_DAN_CHAY.md                     # Báo cáo kỹ thuật chi tiết và hướng dẫn vận hành
├── lib/
│   ├── main.dart                         # Giao diện người dùng CRUD & Luồng đồng bộ Offline-First
│   ├── firebase_options.dart             # Cấu hình FirebaseOptions kết nối dự án topic-db
│   └── database/
│       ├── app_database.dart             # Schema bảng StoredMessages và các hàm truy vấn CRUD
│       └── app_database.g.dart           # File mã nguồn ORM sinh tự động bởi Drift
└── test/
    └── widget_test.dart                  # Bộ kiểm thử tự động toàn diện CRUD In-Memory
```

---

## 3. Hướng dẫn cài đặt và khởi chạy

### Bước 1: Tải các gói thư viện
Tại thư mục `Topic Lab/DB`:
```bash
flutter pub get
```

### Bước 2: Khởi chạy ứng dụng
Chạy ứng dụng trên thiết bị giả lập Android hoặc Windows Desktop:
```bash
flutter run
```

### Bước 3: Chạy bộ kiểm thử tự động
```bash
flutter test
```

---

## 4. Tài liệu chi tiết
Để xem phân tích kỹ thuật, vị trí các dòng mã nguồn quan trọng, cách kiểm tra SQLite bằng Database Inspector trong Android Studio và kịch bản chấm bài chi tiết, vui lòng tham khảo:  
👉 **[HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)**
