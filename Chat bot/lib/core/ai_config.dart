import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý cấu hình tập trung cho Groq Cloud API
class AiConfig {
  static const String defaultModel = 'qwen/qwen3.8-27b';
  static const String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Groq API Key thật đã được cấu hình sẵn
  static String apiKey = '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';

  static const String _prefKey = 'groq_api_key';

  /// Nạp API Key đã lưu từ SharedPreferences
  static Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      apiKey = saved.trim();
    }
  }

  /// Lưu API Key vào SharedPreferences
  static Future<void> saveApiKey(String newKey) async {
    apiKey = newKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, apiKey);
  }

  /// Xóa API Key đã lưu
  static Future<void> clearApiKey() async {
    apiKey = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Kiểm tra xem API Key đã được cấu hình hợp lệ chưa
  static bool get hasValidKey {
    return apiKey.trim().isNotEmpty && apiKey.trim().startsWith('gsk_');
  }
}
