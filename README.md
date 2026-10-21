# TỔNG HỢP CÁC CHỦ ĐỀ THỰC HÀNH (TOPIC LAB)

Thư mục này chứa đầy đủ mã nguồn và tài liệu hướng dẫn chạy cho các chủ đề thực hành theo số thứ tự Topic. Tất cả các bài đều đã được kiểm thử, tương thích với **Android Studio**, **Web (Dart dev)**, và **CLI (flutter run)**.

---

## Danh Sách Các Bài Lab Theo Số Thứ Tự Topic

| STT Topic | Chủ Đề | Thư Mục | Công Nghệ Chính | File Hướng Dẫn |
|:---:|:---|:---|:---|:---|
| **Topic 1** | **Database (Cơ sở dữ liệu)** | `DB/` | Drift (SQLite ORM) Reactive Stream, Cloud Firestore, Offline-first | [HUONG_DAN_CHAY.md](DB/HUONG_DAN_CHAY.md) |
| **Topic 2** | **Bản Đồ (Map)** | `Map/` | Flutter Map, OpenStreetMap tiles, Nominatim Search, OSRM Routing, GPS Live Tracking | [HUONG_DAN_CHAY.md](Map/HUONG_DAN_CHAY.md) |
| **Topic 3** | **Thanh Toán (Payment)** | `Payment/` | Mock Gateway Server (Dart Shelf), HMAC-SHA256 Signature, 2s Polling | [HUONG_DAN_CHAY.md](Payment/HUONG_DAN_CHAY.md) |
| **Topic 4** | **Authentication (Xác thực)** | `Authen/` | Mock Auth (DartPad), Token-based API Login/Register, Google OAuth | [HUONG_DAN_CHAY.md](Authen/HUONG_DAN_CHAY.md) |
| **Topic 6** | **Chat AI (Trợ lý Chatbot AI)** | `Chat bot/` | Groq Cloud API, Model Qwen 3.8, Guardrails du lịch, Multi-turn Context | [HUONG_DAN_CHAY.md](Chat%20bot/HUONG_DAN_CHAY.md) |

---

## Hướng Dẫn Mở & Chạy Bằng Android Studio
1. Khởi động **Android Studio**.
2. Chọn **Open** và trỏ đến thư mục của bài Lab bạn muốn chạy (Ví dụ: `Topic Lab/DB`, `Topic Lab/Map`, `Topic Lab/Payment/app`, `Topic Lab/Authen`, hoặc `Topic Lab/Chat bot`).
3. Chờ Android Studio đồng bộ packages (`flutter pub get`).
4. Chọn thiết bị chạy (Android Emulator hoặc Windows Desktop) và bấm nút **Run (Shift + F10)**.

---

## Chi Tiết Từng Bài

### 1. Topic 1: [Database (DB)](DB)
* Sử dụng kết hợp Drift SQLite (cục bộ) + Cloud Firestore (đám mây) theo mô hình Offline-First.
* Stream dữ liệu thời gian thực: `watchMessages()`.
* Chạy test in-memory tự động: `flutter test`.
* Link xem trực tiếp dữ liệu Cloud qua REST API: [Firestore Messages API](https://firestore.googleapis.com/v1/projects/topic-db/databases/(default)/documents/messages).

### 2. Topic 2: [Bản Đồ (Map)](Map)
* **Q1**: Hiển thị bản đồ OSM tốc độ cao, chọn điểm đi/đến linh hoạt, nút đảo chiều (A ⇄ B), phím Zoom In/Out/Fit Route.
* **Q2**: Tính khoảng cách (km), thời gian (phút), ETA qua OSRM Route API và vẽ PolylineLayer men theo đường phố.
* **Q3**: Mô phỏng xe ô tô chạy theo tuyến đường GPS trực tiếp, camera tự động lia theo xe (Auto-follow).
* Chạy bộ kiểm thử tự động toàn diện: `flutter test` (5/5 tests passed).

### 3. Topic 3: [Thanh Toán (Payment)](Payment)
* `server/`: Chạy bằng `dart run bin/server.dart`.
* `app/`: Gửi đơn hàng có chữ ký HMAC-SHA256, polling mỗi 2s, có nút bấm giả lập thanh toán trực tiếp trên UI.

### 4. Topic 4: [Authentication (Authen)](Authen)
* **Q1**: `lib/question1_mock/mock_auth_dartpad.dart` (Copy chạy thẳng trên DartPad).
* **Q2**: `lib/question2_api/` (Đăng ký, đăng nhập nhận token, lưu SharedPreferences).
* **Q3**: `lib/question3_google/` (Google OAuth, Client ID, Callback URL `footballmanagement://login-callback`).

### 6. Topic 6: [Chat AI (Chat bot)](Chat%20bot)
* **Q1**: Mô phỏng Chatbot bong bóng hai chiều chạy độc lập trên DartPad.
* **Q2**: Kết nối Groq Cloud RESTful API (HTTP POST), xác thực Bearer token, phân tích JSON UTF-8.
* **Q3**: Trợ lý Du lịch với System Prompt Guardrails (từ chối câu hỏi ngoài lề) và duy trì ngữ cảnh Multi-turn.
