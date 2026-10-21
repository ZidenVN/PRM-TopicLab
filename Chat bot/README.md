# BÁO CÁO DỰ ÁN: TOPIC 6 - CHATBOT AI LAB (FLUTTER)
> **Chủ đề (Topic 6):** Xây dựng Trợ lý Chatbot AI (Groq Cloud API & Guardrails)  
> **Tài liệu kỹ thuật chi tiết:** Vui lòng xem [HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)

---

## 1. Giới thiệu dự án
Ứng dụng được xây dựng trên nền tảng **Flutter** nhằm giải quyết trọn vẹn 3 yêu cầu cốt lõi của bài thực hành Topic 6:
1. **Câu 1 (Mock Chatbot):** Mô phỏng giao diện bong bóng chat hai chiều, quản lý danh sách tin nhắn, hiệu ứng tự động cuộn (Auto-scroll) và xử lý bất đồng bộ offline (hoạt động độc lập trên DartPad).
2. **Câu 2 (Basic AI Chatbot):** Kết nối mạng thực tế qua giao thức HTTP POST tới Groq Cloud RESTful API, quản lý Bearer Token, bóc tách cấu trúc dữ liệu JSON đa tầng và kiểm soát các ngoại lệ mạng.
3. **Câu 3 (Travel Guide AI Assistant):** Trợ lý Du lịch thông minh tích hợp cơ chế rào chắn an toàn (Guardrails) trong System Prompt để giới hạn phạm vi chuyên môn du lịch, duy trì ngữ cảnh trò chuyện đa lượt (Multi-turn), và xử lý chính xác các mã lỗi HTTP 429 (Rate Limit) và HTTP 503 (Service Unavailable).

---

## 2. Cấu trúc thư mục dự án

```
Chat bot/
├── pubspec.yaml                          # Khai báo dependency (http, shared_preferences)
├── HUONG_DAN_CHAY.md                     # Báo cáo kỹ thuật chi tiết và hướng dẫn chạy từng câu
├── LAB_INSTRUCTIONS.md                   # Đề bài thực hành gốc
└── lib/
    ├── main.dart                         # Màn hình Portal điều hướng và quản lý cấu hình API Key
    ├── core/
    │   └── ai_config.dart                # Quản lý tập trung Groq API Key và Model (Qwen 3.8)
    ├── question1_mock/
    │   └── mock_chat_dartpad.dart        # [CÂU 1] Hoạt động độc lập 100% trên DartPad hoặc App
    ├── question2_basic_api/
    │   ├── services/basic_ai_service.dart# [CÂU 2] Service gửi HTTP POST tới Groq Cloud
    │   └── screens/basic_chat_screen.dart# [CÂU 2] Màn hình giao diện chat tương tác trực tiếp
    └── question3_travel_guide/
        ├── services/travel_ai_service.dart# [CÂU 3] Guardrails System Prompt & Mảng Multi-turn
        └── screens/travel_chat_screen.dart# [CÂU 3] Màn hình Trợ lý Du lịch đa lượt hội thoại
```

---

## 3. Hướng dẫn cài đặt và khởi chạy

### Bước 1: Chuẩn bị môi trường
* Đảm bảo máy tính đã cài đặt **Flutter SDK 3.x+**.
* Chạy lệnh kiểm tra môi trường:
  ```bash
  flutter doctor
  ```

### Bước 2: Tải các gói thư viện
Tại thư mục gốc dự án, thực thi lệnh:
```bash
flutter pub get
```

### Bước 3: Khởi chạy ứng dụng
Chạy ứng dụng trên thiết bị giả lập Android hoặc Windows Desktop:
```bash
flutter run
```

*Ghi chú:*
* Khóa API của Groq Cloud đã được cấu hình sẵn trong `lib/core/ai_config.dart`.
* Người dùng cũng có thể cập nhật hoặc thay thế API Key trực tiếp trên giao diện bằng biểu tượng ⚙️ (Cài đặt) tại thanh tiêu đề.

---

## 4. Tài liệu chi tiết
Để xem phân tích kiến trúc, trích dẫn dòng mã nguồn quan trọng và kịch bản kiểm thử của từng câu hỏi, vui lòng tham khảo:
👉 **[HUONG_DAN_CHAY.md](HUONG_DAN_CHAY.md)**
