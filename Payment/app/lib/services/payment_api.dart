import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment.dart';

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}

class PaymentApi {
  PaymentApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  // Android emulator kết nối máy chủ qua 10.0.2.2.
  // Trình duyệt Web hoặc Desktop (Windows) gọi localhost:8080.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const _secretKey = 'lab-secret-key';

  String _sign(String data) =>
      Hmac(sha256, utf8.encode(_secretKey)).convert(utf8.encode(data)).toString();

  /// 1. Khởi tạo giao dịch thanh toán kèm chữ ký số HMAC-SHA256
  Future<Payment> createPayment({
    required String orderId,
    required int amount,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/payments'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'orderId': orderId,
              'amount': amount,
              'signature': _sign('amount=$amount&orderId=$orderId'),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 201) throw PaymentException(_errorOf(res));
      return Payment.fromJson(jsonDecode(res.body));
    } on Exception catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Không kết nối được tới cổng thanh toán ($baseUrl): $e');
    }
  }

  /// 2. Tra cứu trạng thái giao dịch (dùng cho cơ chế Polling)
  Future<Payment> getPayment(String id) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/payments/$id'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw PaymentException(_errorOf(res));
      return Payment.fromJson(jsonDecode(res.body));
    } on Exception catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Lỗi khi kiểm tra trạng thái thanh toán: $e');
    }
  }

  /// 3. Giả lập xác nhận thanh toán (thay thế cho curl nếu test nhanh trên app)
  Future<Payment> confirmPayment(String id, {bool success = true}) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/payments/$id/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'result': success ? 'success' : 'failed'}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw PaymentException(_errorOf(res));
      return Payment.fromJson(jsonDecode(res.body));
    } on Exception catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Lỗi khi giả lập xác nhận thanh toán: $e');
    }
  }

  String _errorOf(http.Response res) {
    try {
      return (jsonDecode(res.body) as Map)['message'] as String;
    } catch (_) {
      return 'Lỗi không xác định (${res.statusCode})';
    }
  }
}
