import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/ai_config.dart';

/// Dịch vụ kết nối RESTful API với Groq Cloud (Question 2)
class BasicAiService {
  Future<String> sendMessage(String prompt) async {
    // 1. Kiểm tra nếu chưa có API Key thật thì chuyển sang phản hồi hướng dẫn
    if (!AiConfig.hasValidKey) {
      await Future.delayed(const Duration(milliseconds: 600));
      return '⚠️ Bạn chưa cấu hình Groq API Key!\n\n'
          '👉 Để chat với mô hình LLaMA-3.3 thật:\n'
          '1. Truy cập https://console.groq.com (miễn phí 100%)\n'
          '2. Bấm "Create API Key" và copy mã `gsk_...`\n'
          '3. Bấm vào biểu tượng ⚙️ (Cài đặt) ở góc trên để dán Key vào nhé!';
    }

    // 2. Gửi HTTP POST request lên máy chủ Groq Cloud
    try {
      final response = await http.post(
        Uri.parse(AiConfig.groqApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${AiConfig.apiKey.trim()}',
        },
        body: jsonEncode({
          'model': AiConfig.defaultModel,
          'messages': [
            {
              'role': 'system',
              'content': 'Bạn là một người bạn ảo AI cực kỳ thông minh, nói chuyện tự nhiên bằng tiếng Việt như người thật.\n'
                  'PHONG CÁCH:\n'
                  '- Dùng văn phong tự nhiên đời thường, thân thiện, xưng "mình" và gọi "bạn".\n'
                  '- Khi người dùng trêu đùa, nói chuyện phiếm, chọc ghẹo (như "m gay", "you are gay", "ê", "hôm nay ăn gì"): '
                  'Hãy đối đáp hóm hỉnh, hài hước, tự nhiên như một đứa bạn thân, KHÔNG phân bua máy móc kiểu "Tôi là AI không có giới tính/Tôi chỉ hỗ trợ học tập".\n'
                  '- Khi người dùng hỏi kiến thức kỹ thuật (Flutter, Dart, bài tập, công nghệ): Giải thích rành mạch, chuẩn xác, dễ hiểu.',
            },
            {
              'role': 'user',
              'content': prompt.trim(),
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 20));

      // 3. Xử lý phản hồi từ server
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final String reply = data['choices'][0]['message']['content'];
        return reply.trim();
      } else if (response.statusCode == 401) {
        throw Exception('Mã lỗi HTTP 401 (Unauthorized): API Key không hợp lệ hoặc đã hết hạn.');
      } else if (response.statusCode == 429) {
        throw Exception('Mã lỗi HTTP 429 (Rate Limit): Quá giới hạn lượt gọi API trong 1 phút. Vui lòng chờ 30 giây.');
      } else if (response.statusCode == 503) {
        throw Exception('Mã lỗi HTTP 503 (Service Unavailable): Máy chủ Groq đang bảo trì hoặc quá tải.');
      } else {
        throw Exception('Lỗi máy chủ (${response.statusCode}): ${response.body}');
      }
    } on SocketException {
      throw Exception('Không có kết nối Internet! Vui lòng kiểm tra lại mạng của thiết bị.');
    } on http.ClientException catch (e) {
      throw Exception('Lỗi kết nối Client: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
