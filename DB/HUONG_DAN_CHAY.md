    # BÁO CÁO KỸ THUẬT & HƯỚNG DẪN THỰC THI: TOPIC 1 - DATABASE LAB
> **Chủ đề (Topic 1):** Cơ sở dữ liệu Offline-First (Local Drift SQLite & Cloud Firebase Firestore)

---

## 1. TỔNG QUAN KIẾN TRÚC HỆ THỐNG

Ứng dụng được thiết kế theo mô hình kiến trúc **Offline-First (Ưu tiên hoạt động cục bộ)** tiêu chuẩn trong phát triển phần mềm di động. Hệ thống kết hợp đồng thời hai tầng lưu trữ:

1. **Local Database (Drift SQLite ORM):**
   - Đóng vai trò là nguồn dữ liệu chính (Single Source of Truth) trên thiết bị.
   - Quản lý dữ liệu thông qua cơ chế phản ứng theo luồng thời gian thực (**Reactive Stream**). Mọi thay đổi trong database đều tự động phát tín hiệu để giao diện người dùng cập nhật ngay lập tức mà không cần gọi lại hàm load dữ liệu thủ công.
2. **Cloud Database (Firebase Cloud Firestore):**
   - Kết nối với dịch vụ đám mây thời gian thực của Google (Project ID: `topic-db`).
   - Đảm bảo dữ liệu được sao lưu và đồng bộ đa thiết bị khi có kết nối Internet.

```
                    ┌──────────────────────────────────────────────┐
                    │            NGƯỜI DÙNG THAO TÁC               │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │      GHI VÀO LOCAL SQLITE (DRIFT ORM)        │
                    │         (Luôn thành công, cờ sync: 0)        │
                    └──────────────────────┬───────────────────────┘
                                           │
                     ┌─────────────────────┴─────────────────────┐
                     ▼                                           ▼
          [ CÓ KẾT NỐI INTERNET ]                     [ MẤT KẾT NỐI MẠNG ]
                     │                                           │
        Đồng bộ lên Cloud Firestore                 Dữ liệu an toàn tại máy
       Cập nhật cờ: isSynced = true                 Gắn nhãn: "Chỉ có ở local"
         (Icon đám mây xanh lá)                     (Icon lưu trữ SQLite cục bộ)
```

---

## 2. CẤU TRÚC THƯ MỤC DỰ ÁN

```
DB/
├── pubspec.yaml                          # Cấu hình thư viện (drift, drift_flutter, firebase_core, cloud_firestore)
├── firebase-config.json                  # Cấu hình khóa API kết nối Firebase project topic-db
├── firebase.json                         # Khai báo cấu hình dự án FlutterFire
├── HUONG_DAN_CHAY.md                     # Tài liệu báo cáo kỹ thuật và hướng dẫn vận hành
├── README.md                             # Tổng quan dự án
├── lib/
│   ├── main.dart                         # Giao diện người dùng CRUD & Luồng đồng bộ Offline-First
│   ├── firebase_options.dart             # Cấu hình tham số FirebaseOptions kết nối dự án topic-db
│   └── database/
│       ├── app_database.dart             # Khai báo Schema bảng StoredMessages và các truy vấn CRUD
│       └── app_database.g.dart           # Mã nguồn ORM sinh tự động bởi Drift / build_runner
└── test/
    └── widget_test.dart                  # Bộ kiểm thử tự động toàn diện CRUD trên SQLite In-Memory
```

---

## 3. CÁC THÀNH PHẦN KỸ THUẬT VÀ PHƯƠNG THỨC CRUD TRONG MÃ NGUỒN

Toàn bộ logic thao tác dữ liệu được module hóa rõ ràng giữa tầng Database Service và tầng Giao diện:

### 3.1. Tầng Database Cục bộ ([`lib/database/app_database.dart`](lib/database/app_database.dart))

* **Định nghĩa lược đồ bảng `StoredMessages` (Dòng 6 - 14):**
  - `id`: Khóa chính định danh chuỗi UUID v4.
  - `content`: Nội dung văn bản lưu trữ.
  - `createdAt`: Dấu thời gian khởi tạo bản ghi.
  - `isSynced`: Cờ boolean đánh dấu trạng thái đồng bộ lên đám mây (mặc định: `false`).

* **Truy vấn Reactive Stream — `watchMessages()` (Dòng 39 - 43):**
  ```dart
  Stream<List<StoredMessage>> watchMessages() {
    return (select(storedMessages)..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).watch();
  }
  ```
  *Ý nghĩa:* Trả về luồng dữ liệu `Stream`. Mỗi khi có lệnh thêm, sửa, hoặc xóa dữ liệu trong SQLite, Drift tự động phát dữ liệu mới nhất, giúp `StreamBuilder` trên UI vẽ lại tức thì.

* **Thêm bản ghi — `addMessage()` (Dòng 45 - 57):**
  - Thực hiện câu lệnh SQL `INSERT INTO stored_messages` với đối tượng `StoredMessagesCompanion`.

* **Cập nhật trạng thái đồng bộ — `markAsSynced()` (Dòng 59 - 62):**
  - Cập nhật cờ `isSynced = true` sau khi bản ghi được gửi thành công lên Firebase Firestore.

* **Chỉnh sửa nội dung — `updateMessageContent()` (Dòng 65 - 72):**
  - Thực hiện câu lệnh SQL `UPDATE` nội dung văn bản mới và đặt lại cờ `isSynced = false` để chuẩn bị cho chu kỳ đồng bộ tiếp theo.

* **Xóa bản ghi — `deleteMessage()` & `clearAllMessages()` (Dòng 75 - 82):**
  - Thực thi lệnh `DELETE` theo ID hoặc xóa toàn bộ bảng dữ liệu.

---

### 3.2. Tầng Giao diện & Điều phối Đồng bộ ([`lib/main.dart`](lib/main.dart))

* **Create (Tạo mới) — `_saveMessage()` (Dòng 144 - 192):**
  - Người dùng nhập văn bản ➔ Lưu ngay vào SQLite cục bộ qua `_database.addMessage()`.
  - Nếu Cloud Firestore đang ở trạng thái sẵn sàng, app tiếp tục ghi bản ghi vào collection `messages` trên Firestore và gọi `_database.markAsSynced()`.
  - Nếu không có mạng: Dữ liệu vẫn được bảo toàn trọn vẹn ở SQLite, thông báo *"Đã lưu vào SQLite cục bộ (Offline)"*.

* **Read (Đọc & Lắng nghe) — `StreamBuilder` (Dòng 427 - 567):**
  - Lắng nghe luồng dữ liệu từ `_messagesStream`. Hiển thị danh sách bản ghi kèm nhãn trạng thái trực quan: `Đã đồng bộ` (màu xanh lá) hoặc `Chỉ có ở local` (màu hổ phách).
  - Tích hợp tính năng chạm vào bản ghi để sao chép nội dung vào Clipboard.

* **Update (Chỉnh sửa) — `_openEditDialog()` & `_updateMessage()` (Dòng 195 - 236):**
  - Nhấn biểu tượng ✏️ để mở hộp thoại cập nhật nội dung.
  - Khi lưu: Cập nhật trực tiếp vào SQLite và gửi lệnh `update` lên tài liệu tương ứng trên Firestore.

* **Delete (Xóa dữ liệu) — `_deleteMessage()` & `_confirmClearAll()` (Dòng 239 - 279):**
  - Nhấn biểu tượng 🗑️ để xóa bản ghi khỏi SQLite và xóa document tương ứng trên Firestore.
  - Nút *"Xóa tất cả"* có hộp thoại xác nhận giúp dọn sạch database khi cần thực hiện chu kỳ kiểm thử mới.

* **Retry Sync (Đồng bộ thủ công) — `_syncSingleMessage()` (Dòng 282 - 299):**
  - Nhấn biểu tượng 🔄 trên các bản ghi có nhãn *"Chỉ có ở local"* để thực hiện đồng bộ lại lên Cloud Firestore.

---

## 4. VỊ TRÍ LƯU TRỮ VẬT LÝ & CÁCH KIỂM TRA TRÊN ANDROID STUDIO

### 4.1. Đường dẫn lưu trữ SQLite trên máy ảo / thiết bị Android:
Cơ sở dữ liệu SQLite được lưu trữ tại phân vùng nội bộ của ứng dụng:
```
/data/data/com.example.connect_db/databases/connect_db
```

### 4.2. Thao tác kiểm tra dữ liệu bằng Database Inspector (Android Studio):
1. Chạy ứng dụng trên máy ảo Android (Pixel / Android Emulator).
2. Trên thanh công cụ dưới đáy Android Studio, mở tab **App Inspection** ➔ chọn thẻ **Database Inspector**.
3. Tại khung bên trái, hệ thống hiển thị tiến trình `com.example.connect_db`, cơ sở dữ liệu `connect_db` và bảng `stored_messages`.
4. Nhấn đúp chuột vào bảng `stored_messages`: Toàn bộ các trường dữ liệu (`id`, `content`, `created_at`, `is_synced`) sẽ hiển thị trực quan dạng bảng.
5. Khi người dùng thực hiện thao tác Thêm / Sửa / Xóa trên app, dữ liệu trên bảng Database Inspector tự động cập nhật thời gian thực.
6. Có thể mở tab **New Query** để chạy trực tiếp câu truy vấn SQL:
   ```sql
   SELECT * FROM stored_messages ORDER BY created_at DESC;
   ```

### 4.3. Kiểm tra dữ liệu trên Cloud Firebase Firestore:

#### Cách 1: Xem qua REST API trực tiếp trên trình duyệt (Khuyên dùng - Không cần tài khoản hay cấp quyền):
Bất kỳ ai (kể cả Giảng viên hay người chấm bài) đều có thể click xem dữ liệu đám mây realtime ngay lập tức trên trình duyệt mà không cần tài khoản Google:
* **Xem toàn bộ danh sách bản ghi đã đồng bộ:**  
  👉 [https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages](https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages)
* **Tra cứu trực tiếp từng bản ghi theo `id`:**  
  👉 `https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages/{id}`  
  *(Khi app tạo một bản ghi có ID cụ thể, dán ID vào cuối đường dẫn trên để xem nội dung document JSON tương ứng).*

#### Cách 2: Xem qua giao diện đồ họa Firebase Console (Dành cho tài khoản quản trị):
1. Truy cập trực tiếp tại: [Firebase Console - topic-db](https://console.firebase.google.com/project/topic-db/firestore/databases/-default-/data).
2. Vào mục **Build ➔ Firestore Database ➔ collection `messages`**.
3. Bảng điều khiển sẽ hiển thị trực quan các document và trường dữ liệu tương ứng.
*(Lưu ý: Nếu chia sẻ link này cho người khác, cần vào `Project Settings -> Users and permissions` để cấp quyền Viewer cho Gmail của họ).*

---

## 5. HƯỚNG DẪN KHỞI CHẠY VÀ KỊCH BẢN KIỂM THỬ

### 5.1. Lệnh khởi chạy ứng dụng:
```bash
cd "Topic Lab/DB"
flutter pub get
flutter run
```

### 5.2. Chạy bộ kiểm thử tự động (Unit Test & Widget Test):
```bash
flutter test
```
*Kết quả:* Bộ test thực thi trên SQLite In-Memory Database (`NativeDatabase.memory()`), kiểm thử độc lập không phụ thuộc mạng:
- Kiểm thử tạo bản ghi (`Create`).
- Kiểm thử đọc dữ liệu và kiểm tra cờ `isSynced: false` (`Read`).
- Kiểm thử chuyển đổi cờ sang `isSynced: true` (`Sync`).
- Kiểm thử chỉnh sửa nội dung bản ghi (`Update`).
- Kiểm thử xóa từng bản ghi và xóa toàn bộ bảng (`Delete`).
- Kiểm thử render giao diện và badge trạng thái kết nối.

### 5.3. Kịch bản kiểm thử đề xuất dành cho Giảng viên:

* **Kịch bản 1 — Kiểm thử Thêm mới và Đồng bộ Realtime (Create & Sync):**
  - Nhập nội dung: *"Kiểm thử đồng bộ dữ liệu"* ➔ Bấm **Lưu vào SQLite**.
  - Kết quả: Bản ghi xuất hiện ngay lập tức trong danh sách bên dưới với nhãn `Đã đồng bộ` (icon xanh lá). Mở link REST API `.../documents/messages` (hoặc Firebase Console) thấy document mới xuất hiện tức thì với ID tương ứng.

* **Kịch bản 2 — Kiểm thử Chỉnh sửa nội dung (Update):**
  - Bấm vào icon ✏️ của bản ghi ➔ Đổi nội dung thành *"Nội dung đã được chỉnh sửa"* ➔ Bấm **Lưu thay đổi**.
  - Kết quả: Nội dung cập nhật ngay lập tức trên danh sách và đồng bộ lên Firebase Firestore. F5 lại link API thấy trường `content` đã được cập nhật nội dung mới.

* **Kịch bản 3 — Kiểm thử Xóa bản ghi (Delete):**
  - Bấm vào icon 🗑️ của bản ghi.
  - Kết quả: Bản ghi biến mất khỏi danh sách SQLite và document trên Firebase bị xóa. F5 lại link API thấy document đã biến mất.

* **Kịch bản 4 — Kiểm thử cơ chế Khả dụng cao Offline-First (Fault Tolerance):**
  - Ngắt kết nối Wi-Fi/Internet trên máy ảo (bật Airplane Mode).
  - Nhập nội dung: *"Tin nhắn lưu lúc offline"* ➔ Bấm **Lưu vào SQLite**.
  - Kết quả: Ứng dụng **hoạt động bình thường, không xảy ra crash**. Bản ghi được lưu an toàn tại SQLite với nhãn `Chỉ có ở local`.
  - Bật lại kết nối Internet ➔ Bấm nút icon 🔄 tại bản ghi đó ➔ Trạng thái chuyển đổi thành `Đã đồng bộ`.
