# HƯỚNG DẪN THỰC THI & TÀI LIỆU KỸ THUẬT: TOPIC 6 - CHATBOT AI LAB
> **Chủ đề (Topic 6):** Xây dựng Trợ lý Chatbot AI (Groq Cloud API & Guardrails)

---

## 1. TỔNG QUAN KIẾN TRÚC 3 CÂU HỎI (TOPIC 6)

Dự án Chatbot AI được tổ chức theo cấu trúc module rõ ràng, đáp ứng toàn diện các tiêu chí kỹ thuật từ mô phỏng giao diện đến tích hợp mô hình ngôn ngữ lớn (LLM):

```
[ CÂU 1: Mock Chatbot ] ──────► [ CÂU 2: Basic Chatbot ] ──────► [ CÂU 3: Travel Assistant ]
(DartPad - State/Logic)            (Groq REST API Thật)            (Guardrails & Multi-turn)
```

| Câu hỏi | Tên bài | File mã nguồn chính | Mục tiêu kỹ thuật cốt lõi |
| :--- | :--- | :--- | :--- |
| **Câu 1** | **Mô phỏng Chatbot (DartPad)** | [`lib/question1_mock/mock_chat_dartpad.dart`](lib/question1_mock/mock_chat_dartpad.dart) | Quản lý danh sách tin nhắn, bong bóng chat hai chiều, auto-scroll, độ trễ 800ms giả lập bất đồng bộ (chạy độc lập không cần mạng/key). |
| **Câu 2** | **Chatbot kết nối Groq API** | [`lib/question2_basic_api/`](lib/question2_basic_api/) | Giao tiếp mạng qua HTTP POST tới Groq Cloud, Header Bearer Token, bóc tách chuỗi JSON đa tầng và bắt ngoại lệ mạng an toàn. |
| **Câu 3** | **Trợ lý Du lịch & Giữ ngữ cảnh** | [`lib/question3_travel_guide/`](lib/question3_travel_guide/) | Rào chắn an toàn (Guardrails) khống chế phạm vi du lịch, duy trì ngữ cảnh hội thoại đa lượt (Multi-turn), xử lý mã lỗi HTTP 429 và 503. |

---

## 2. CẤU TRÚC THƯ MỤC DỰ ÁN

```
Chat bot/
├── pubspec.yaml                          # Khai báo thư viện http và shared_preferences
├── HUONG_DAN_CHAY.md                     # Tài liệu hướng dẫn thực thi và báo cáo kỹ thuật
├── LAB_INSTRUCTIONS.md                   # Đề bài thực hành gốc
└── lib/
    ├── main.dart                         # Màn hình Portal điều hướng 3 câu và quản lý API Key
    ├── core/
    │   └── ai_config.dart                # Quản lý tập trung Groq API Key và Model cấu hình
    ├── question1_mock/
    │   └── mock_chat_dartpad.dart        # [CÂU 1] Mã nguồn độc lập 100%, chạy trên DartPad hoặc ứng dụng Flutter
    ├── question2_basic_api/
    │   ├── services/basic_ai_service.dart# [CÂU 2] Tầng Service HTTP POST gửi prompt tới Groq Cloud
    │   └── screens/basic_chat_screen.dart# [CÂU 2] Màn hình giao diện chat kết nối trực tiếp API
    └── question3_travel_guide/
        ├── services/travel_ai_service.dart# [CÂU 3] System Prompt Guardrails & Quản lý mảng hội thoại Multi-turn
        └── screens/travel_chat_screen.dart# [CÂU 3] Màn hình Trợ lý Du lịch hỗ trợ đối thoại đa lượt
```

---

## 3. HƯỚNG DẪN THỰC THI & GIẢI THÍCH CHI TIẾT MÃ NGUỒN TỪNG CÂU

---

### 🟢 CÂU 1: MÔ PHỎNG CHATBOT TRÊN DARTPAD (`mock_chat_dartpad.dart`)

#### 1. Hướng dẫn thực thi:
* **Phương án A (Trên trình duyệt web DartPad):**
  1. Mở trình duyệt web, truy cập: **[https://dartpad.dev](https://dartpad.dev)**.
  2. Chọn chế độ làm việc: **Flutter**.
  3. Mở file [`lib/question1_mock/mock_chat_dartpad.dart`](lib/question1_mock/mock_chat_dartpad.dart), nhấn `Ctrl + A` sao chép toàn bộ nội dung và dán vào DartPad.
  4. Nhấn **Run** để khởi chạy ứng dụng trực tiếp trên trình duyệt.
* **Phương án B (Trên ứng dụng Flutter):** Khởi chạy ứng dụng qua lệnh `flutter run`, tại màn hình Portal chính chọn thẻ **"CÂU 1: Mô phỏng Chatbot (DartPad)"**.

#### 2. Các thành phần kỹ thuật quan trọng trong mã nguồn:

* **📌 Điểm 1: Cấu trúc dữ liệu tin nhắn `MockChatMessage` (Dòng 39 - 49)**
  ```dart
  class MockChatMessage {
    final String text;        // Nội dung tin nhắn
    final bool isUser;        // true: Người dùng (căn phải), false: Bot (căn trái)
    final DateTime timestamp; // Thời điểm tạo tin nhắn
  }
  ```
  * *Mục đích:* Cấu trúc dữ liệu tiêu chuẩn để quản lý danh sách tin nhắn và render giao diện bong bóng chat hai chiều trực quan.

* **📌 Điểm 2: Giả lập độ trễ bất đồng bộ trong `MockAiService` (Dòng 228 - 231)**
  ```dart
  await Future.delayed(const Duration(milliseconds: 800));
  ```
  * *Mục đích:* Giả lập độ trễ mạng thực tế (Network Latency) thông qua cơ chế bất đồng bộ (`async/await`), giúp giao diện kích hoạt cờ trạng thái xử lý trước khi trả về kết quả.

* **📌 Điểm 3: Tự động cuộn danh sách với `addPostFrameCallback` (Dòng 277 - 287)**
  ```dart
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  ```
  * *Mục đích:* `addPostFrameCallback` đảm bảo Flutter hoàn tất chu kỳ vẽ (render) widget tin nhắn mới lên màn hình rồi mới tính toán chiều cao và thực hiện hiệu ứng cuộn mượt xuống đáy, tránh lỗi sai lệch vị trí do kích thước danh sách chưa kịp cập nhật.

* **📌 Điểm 4: Quản lý cờ trạng thái `_isAiTyping` (Dòng 275, 302, 323)**
  * *Mục đích:* Khi người dùng gửi tin nhắn, biến `_isAiTyping` được bật `true` để:
    1. Hiển thị thông báo tiến trình "AI đang suy nghĩ...".
    2. Vô hiệu hóa nút gửi và ô nhập liệu (`enabled: !_isAiTyping`), ngăn người dùng gửi nhiều thao tác trùng lặp cùng lúc.

---

### 🟣 CÂU 2: CHATBOT KẾT NỐI GROQ RESTFUL API

#### 1. Hướng dẫn thực thi:
1. Mở ứng dụng và chọn thẻ **"CÂU 2: Chatbot kết nối Groq API"**.
2. Nhập câu hỏi bất kỳ vào ô nhập liệu và gửi đi. Ứng dụng sẽ thực hiện HTTP POST trực tiếp đến máy chủ Groq Cloud và nhận phản hồi từ mô hình LLM (`qwen/qwen3.8-27b`).

#### 2. Các thành phần kỹ thuật quan trọng trong mã nguồn:

* **📌 Điểm 1: Cấu hình Headers và phương thức HTTP POST ([`basic_ai_service.dart`](lib/question2_basic_api/services/basic_ai_service.dart), Dòng 21 - 26)**
  ```dart
  final response = await http.post(
    Uri.parse(AiConfig.groqApiUrl), // https://api.groq.com/openai/v1/chat/completions
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer ${AiConfig.apiKey.trim()}',
    },
    ...
  );
  ```
  * *Mục đích:* 
    * `Content-Type: application/json; charset=utf-8`: Khai báo dữ liệu truyền tải là JSON chuẩn quốc tế và hỗ trợ đầy đủ ký tự Unicode tiếng Việt.
    * `Authorization: Bearer <API_KEY>`: Cơ chế xác thực Bearer Token bắt buộc theo chuẩn API của Groq Cloud.

* **📌 Điểm 2: Cấu trúc Body Payload gửi lên máy chủ (Dòng 27 - 46)**
  ```dart
  body: jsonEncode({
    'model': AiConfig.defaultModel,
    'messages': [
      {'role': 'system', 'content': '...'},
      {'role': 'user', 'content': prompt.trim()},
    ],
    'temperature': 0.7,
    'max_tokens': 1024,
  })
  ```
  * *Mục đích:* Đóng gói cấu trúc yêu cầu theo chuẩn OpenAI Specification: chỉ định tên mô hình, System role định hình phong cách phản hồi tự nhiên, User role chứa nội dung câu hỏi, cùng các tham số giới hạn token.

* **📌 Điểm 3: Bóc tách chuỗi JSON phản hồi (Dòng 50 - 53)**
  ```dart
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    final String reply = data['choices'][0]['message']['content'];
    return reply.trim();
  }
  ```
  * *Mục đích:* Sử dụng `utf8.decode(response.bodyBytes)` để đảm bảo văn bản tiếng Việt có dấu hiển thị chính xác không bị lỗi font, sau đó trích xuất nội dung văn bản từ mảng `choices[0]['message']['content']`.

* **📌 Điểm 4: Xử lý ngoại lệ mạng và mã trạng thái HTTP (Dòng 54 - 69)**
  * *Mục đích:* Sử dụng khối `try-catch` kiểm soát toàn diện:
    * `HTTP 401`: Báo lỗi khóa API không hợp lệ.
    * `HTTP 429`: Báo lỗi vượt quá tần suất gọi API (Rate Limit).
    * `HTTP 503`: Báo lỗi máy chủ dịch vụ đang bận hoặc bảo trì.
    * `SocketException`: Bắt lỗi thiết bị mất kết nối mạng.
    * Nhờ đó ứng dụng đưa ra thông báo tường minh trên giao diện, bảo đảm tính ổn định và ngăn ngừa sự cố crash ứng dụng.

---

### 🔵 CÂU 3: TRỢ LÝ DU LỊCH & GIỮ NGỮ CẢNH (GUARDRAILS & MULTI-TURN)

#### 1. Hướng dẫn thực thi & Kịch bản kiểm thử:
1. Mở ứng dụng và chọn thẻ **"CÂU 3: Trợ lý Du lịch & Giữ ngữ cảnh"**.
2. **Kịch bản 1 — Kiểm thử truy vấn đúng chủ đề du lịch:**
   * Thao tác: Nhập câu hỏi: *"Gợi ý cho mình lịch trình du lịch Đà Lạt 2 ngày 1 đêm"*
   * Kết quả: AI phân tích và đưa ra lịch trình tham quan, ẩm thực chi tiết theo từng buổi sáng, chiều, tối.
3. **Kịch bản 2 — Kiểm thử khả năng duy trì ngữ cảnh hội thoại (Multi-turn):**
   * Thao tác: Nhập tiếp câu hỏi nối tiếp: *"Ở đó có lạnh không, nên mặc đồ gì?"*
   * Kết quả: AI tự động phân tích ngữ cảnh từ câu hỏi trước, nhận diện đại từ *"ở đó"* chính là Đà Lạt mà không cần người dùng nhắc lại tên địa danh.
4. **Kịch bản 3 — Kiểm thử rào chắn an toàn (Guardrails):**
   * Thao tác: Nhập câu hỏi nằm ngoài phạm vi du lịch (Ví dụ: *"Viết giúp mình một đoạn code Flutter tạo nút bấm"* hoặc *"Giải giúp mình bài toán tích phân này"*).
   * Kết quả: AI tuân thủ rào chắn an toàn (Guardrails), từ chối lịch sự theo System Prompt và hướng dẫn người dùng quay lại các chủ đề liên quan đến du lịch.

#### 2. Các thành phần kỹ thuật quan trọng trong mã nguồn:

* **📌 Điểm 1: Thiết lập rào chắn an toàn Guardrails trong System Prompt ([`travel_ai_service.dart`](lib/question3_travel_guide/services/travel_ai_service.dart), Dòng 26 - 44)**
  ```dart
  static const String travelSystemPrompt = '''
  Bạn là "Trợ lý Ảo Hướng Dẫn Viên Du Lịch Thông Minh".
  QUY TẮC BẮT BUỘC (GUARDRAILS KHỐNG CHẾ CHỦ ĐỀ):
  1. PHẠM VI CHO PHÉP: Bạn CHỈ ĐƯỢC PHÉP tư vấn các chủ đề liên quan đến DU LỊCH...
  2. QUY TẮC TỪ CHỐI NGHIÊM NGẶT: Nếu người dùng hỏi bất kỳ chủ đề nào KHÔNG LIÊN QUAN ĐẾN DU LỊCH (viết code, giải toán, thể thao, thời sự...):
     BẠN BẮT BUỘC PHẢI TỪ CHỐI MỘT CÁCH LỊCH SỰ...
  ''';
  ```
  * *Mục đích:* Cơ chế rào chắn an toàn (Guardrails) được cấu hình ngay tại cấp độ `role: "system"`. Kỹ thuật này giới hạn phạm vi sinh ngôn ngữ của mô hình LLM, đảm bảo ứng dụng chỉ phục vụ nghiệp vụ du lịch theo đúng yêu cầu bài Lab.

* **📌 Điểm 2: Cơ chế duy trì ngữ cảnh hội thoại đa lượt Multi-turn (Dòng 55 - 78)**
  ```dart
  // 1. Khởi tạo System Prompt tại vị trí đầu tiên
  final List<Map<String, String>> messagesPayload = [
    {'role': 'system', 'content': travelSystemPrompt},
  ];

  // 2. Nối toàn bộ lịch sử các cặp user - assistant trước đó
  for (final msg in history) {
    if (msg.isError) continue;
    if (msg.role == 'user' || msg.role == 'assistant') {
      messagesPayload.add({
        'role': msg.role,
        'content': msg.content,
      });
    }
  }

  // 3. Thêm câu hỏi mới nhất của người dùng
  messagesPayload.add({'role': 'user', 'content': userPrompt.trim()});
  ```
  * *Mục đích:* Bản chất giao thức RESTful API là **Stateless** (phi trạng thái, không tự ghi nhớ các yêu cầu trước). Để mô hình AI hiểu được ngữ cảnh xuyên suốt, ứng dụng duyệt mảng lịch sử trò chuyện và đóng gói toàn bộ chuỗi hội thoại gửi kèm vào trường `messages` trong mỗi lần gửi HTTP POST.

* **📌 Điểm 3: Bắt và phân loại cụ thể các mã lỗi HTTP (Dòng 100 - 110)**
  ```dart
  } else if (response.statusCode == 429) {
    throw Exception('Mã lỗi HTTP 429 (Rate Limit / Quota Exceeded): Bạn đã vượt quá giới hạn lượt gọi API...');
  } else if (response.statusCode == 503) {
    throw Exception('Mã lỗi HTTP 503 (Service Unavailable): Máy chủ AI đang bảo trì hoặc quá tải...');
  }
  ```
  * *Mục đích:* Phân loại tường minh hai mã trạng thái phổ biến khi tích hợp dịch vụ AI trên Cloud: HTTP 429 (vượt hạn mức tần suất gọi API) và HTTP 503 (máy chủ nhà cung cấp quá tải hoặc tạm ngừng hoạt động), giúp giao diện hiển thị thông báo chính xác cho người dùng.
