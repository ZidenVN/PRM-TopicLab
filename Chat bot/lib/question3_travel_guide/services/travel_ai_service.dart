import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/ai_config.dart';

/// Tin nhắn ngữ cảnh hỗ trợ Multi-turn Conversation
class TravelMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final bool isError;

  const TravelMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == 'user';
}

/// Dịch vụ AI chuyên biệt cho Trợ lý Du lịch với Guardrails và Multi-turn (Question 3)
class TravelAiService {
  /// System Prompt với Guardrails khống chế phạm vi chủ đề Du Lịch nghiêm ngặt
  static const String travelSystemPrompt = '''
Bạn là "Trợ lý Ảo Hướng Dẫn Viên Du Lịch Thông Minh" (Travel Guide AI Assistant) được tích hợp trong ứng dụng di động Flutter.

QUY TẮC BẮT BUỘC (GUARDRAILS KHỐNG CHẾ CHỦ ĐỀ):
1. PHẠM VI CHO PHÉP: Bạn CHỈ ĐƯỢC PHÉP tư vấn các chủ đề liên quan đến DU LỊCH, bao gồm:
   - Gợi ý địa điểm tham quan, danh lam thắng cảnh, bảo tàng, khu vui chơi.
   - Lên lịch trình du lịch (1 ngày, 2 ngày 1 đêm, 3N2Đ, xuyên Việt, du lịch quốc tế).
   - Ẩm thực địa phương, đặc sản, nhà hàng, quán ăn ngon.
   - Phương tiện di chuyển (vé máy bay, tàu hỏa, xe khách, thuê xe máy).
   - Khách sạn, resort, homestay, chi phí dự kiến và mẹo tiết kiệm ngân sách.
   - Văn hóa, thời tiết, phong tục tập quán và trang phục phù hợp khi đi du lịch.

2. QUY TẮC TỪ CHỐI NGHIÊM NGẶT (TUYỆT ĐỐI TUÂN THỦ):
   - Nếu người dùng hỏi bất kỳ chủ đề nào KHÔNG LIÊN QUAN ĐẾN DU LỊCH (ví dụ: viết code/lập trình, giải bài tập toán/lý/hóa, bình luận bóng đá, thời sự chính trị, sáng tác thơ tình, tâm sự đời sống, chém gió linh tinh...):
   - BẠN BẮT BUỘC PHẢI TỪ CHỐI MỘT CÁCH LỊCH SỰ, giải thích rõ bạn là trợ lý chuyên trách du lịch và gợi ý người dùng đặt các câu hỏi về du lịch hoặc khám phá vùng đất mới.
   - Mẫu từ chối chuẩn: "Xin lỗi bạn, tôi là Trợ lý Hướng dẫn viên Du lịch. Tôi chỉ có thể hỗ trợ các thông tin về địa điểm tham quan, ẩm thực, lịch trình và kinh nghiệm du lịch. Bạn có muốn tôi gợi ý một điểm đến thú vị nào cho chuyến đi sắp tới không?"

3. PHONG CÁCH: Thân thiện, nhiệt huyết, hiếu khách, sử dụng tiếng Việt tự nhiên và súc tích.
''';

  /// Gửi tin nhắn kèm toàn bộ lịch sử ngữ cảnh (Multi-turn conversation)
  Future<String> sendTravelMessage(List<TravelMessage> history, String userPrompt) async {
    // 1. Kiểm tra API Key
    if (!AiConfig.hasValidKey) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _generateOfflineTravelFallback(userPrompt);
    }

    // 2. Xây dựng payload mảng `messages` chứa System Prompt + Lịch sử hội thoại
    final List<Map<String, String>> messagesPayload = [
      {
        'role': 'system',
        'content': travelSystemPrompt,
      },
    ];

    // Thêm các lượt trò chuyện trước đó để AI hiểu ngữ cảnh tiếp nối
    for (final msg in history) {
      if (msg.isError) continue;
      if (msg.role == 'user' || msg.role == 'assistant') {
        messagesPayload.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
    }

    // Thêm câu hỏi mới nhất của người dùng
    messagesPayload.add({
      'role': 'user',
      'content': userPrompt.trim(),
    });

    // 3. Gửi request tới Groq Cloud
    try {
      final response = await http.post(
        Uri.parse(AiConfig.groqApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${AiConfig.apiKey.trim()}',
        },
        body: jsonEncode({
          'model': AiConfig.defaultModel,
          'messages': messagesPayload,
          'temperature': 0.6,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 25));

      // 4. Kiểm soát mã lỗi nâng cao theo yêu cầu Đề bài Lab
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final String reply = data['choices'][0]['message']['content'];
        return reply.trim();
      } else if (response.statusCode == 429) {
        throw Exception(
          'Mã lỗi HTTP 429 (Rate Limit / Quota Exceeded): '
          'Bạn đã vượt quá giới hạn lượt gọi API của Groq trong phút này. Vui lòng chờ 30 giây rồi thử lại!',
        );
      } else if (response.statusCode == 503) {
        throw Exception(
          'Mã lỗi HTTP 503 (Service Unavailable): '
          'Máy chủ AI đang bảo trì hoặc quá tải. Vui lòng thử lại sau giây lát!',
        );
      } else if (response.statusCode == 401) {
        throw Exception(
          'Mã lỗi HTTP 401 (Unauthorized): '
          'API Key Groq không hợp lệ hoặc đã bị vô hiệu hóa. Vui lòng kiểm tra lại trên console.groq.com.',
        );
      } else {
        throw Exception('Lỗi máy chủ (${response.statusCode}): ${response.body}');
      }
    } on SocketException {
      throw Exception('Không thể kết nối Internet! Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.');
    } on http.ClientException catch (e) {
      throw Exception('Lỗi kết nối Client: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Mô phỏng kiểm tra Guardrails offline nếu chưa có mạng/key
  String _generateOfflineTravelFallback(String prompt) {
    final lower = prompt.toLowerCase();
    // Bắt bẫy lạc đề theo đúng tiêu chí nghiệm thu đề bài
    final nonTravelKeywords = ['code', 'viết code', 'lập trình', 'toán', 'giải toán', 'bóng đá', 'thời sự', 'thơ'];
    final isOffTopic = nonTravelKeywords.any((kw) => lower.contains(kw));

    if (isOffTopic) {
      return '🛡️ [Guardrails Từ Chối Lạc Đề]:\n'
          'Xin lỗi bạn, tôi là Trợ lý Hướng dẫn viên Du lịch chuyên nghiệp. '
          'Tôi không thể hỗ trợ các chủ đề ngoài du lịch như lập trình, giải toán hay thời sự. '
          'Bạn có muốn tôi tư vấn một địa điểm du lịch tuyệt vời nào không?';
    }

    if (lower.contains('đà lạt')) {
      return '🌲 [Tư vấn Du lịch Đà Lạt]:\n'
          'Đà Lạt thời tiết se lạnh quanh năm rất lý tưởng! '
          'Gợi ý: Tham quan Thung lũng Tình Yêu, Quảng trường Lâm Viên, Đồi chè Cầu Đất. '
          'Ẩm thực: Bánh tráng nướng, lẩu gà lá é, kem bơ Thanh Thảo!';
    }

    return '✈️ Tôi là Trợ lý Du lịch (Chế độ mô phỏng). '
        'Hãy nhập Groq API Key để kích hoạt AI LLaMA-3.3 thật và trải nghiệm trọn vẹn Guardrails nhé!';
  }
}
