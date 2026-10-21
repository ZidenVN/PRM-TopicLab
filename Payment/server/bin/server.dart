import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

const secretKey = 'lab-secret-key';
final payments = <String, Map<String, dynamic>>{};
int _counter = 1000;

String sign(String data) =>
    Hmac(sha256, utf8.encode(secretKey)).convert(utf8.encode(data)).toString();

Response jsonResponse(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json',
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, OPTIONS',
        'access-control-allow-headers': 'Origin, Content-Type, Accept, Authorization',
      },
    );

Middleware corsHeaders() => (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'access-control-allow-origin': '*',
            'access-control-allow-methods': 'GET, POST, OPTIONS',
            'access-control-allow-headers': 'Origin, Content-Type, Accept, Authorization',
          });
        }
        final response = await innerHandler(request);
        return response.change(headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET, POST, OPTIONS',
          'access-control-allow-headers': 'Origin, Content-Type, Accept, Authorization',
        });
      };
    };

void main() async {
  final router = Router();

  // 1. Tạo giao dịch (POST /api/payments)
  router.post('/api/payments', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final amount = body['amount'];
    final orderId = body['orderId'];
    final signature = body['signature'];

    if (amount is! int || amount <= 0 || orderId is! String) {
      return jsonResponse(
        {'code': 'INVALID_DATA', 'message': 'Dữ liệu không hợp lệ'},
        status: 400,
      );
    }

    final expectedSignature = sign('amount=$amount&orderId=$orderId');
    if (signature != expectedSignature) {
      return jsonResponse(
        {'code': 'INVALID_SIGNATURE', 'message': 'Chữ ký không hợp lệ'},
        status: 401,
      );
    }

    final id = 'PAY${_counter++}';
    payments[id] = {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
    };

    print('[Mock Gateway] Đã tạo giao dịch: $id (Số tiền: $amount VND, Order: $orderId)');
    return jsonResponse(payments[id]!, status: 201);
  });

  // 2. Tra cứu trạng thái giao dịch (GET /api/payments/<id>)
  router.get('/api/payments/<id>', (Request req, String id) {
    final p = payments[id];
    if (p == null) {
      return jsonResponse(
        {'code': 'NOT_FOUND', 'message': 'Không tìm thấy giao dịch'},
        status: 404,
      );
    }
    return jsonResponse(p);
  });

  // 3. Giả lập thanh toán hoàn tất (POST /api/payments/<id>/confirm)
  router.post('/api/payments/<id>/confirm', (Request req, String id) async {
    final p = payments[id];
    if (p == null) {
      return jsonResponse(
        {'code': 'NOT_FOUND', 'message': 'Không tìm thấy giao dịch'},
        status: 404,
      );
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final result = body['result'] == 'failed' ? 'FAILED' : 'SUCCESS';
    p['status'] = result;
    print('[Mock Gateway] Cập nhật giao dịch $id -> $result');
    return jsonResponse(p);
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('======================================================');
  print(' Mock Payment Gateway Server đang chạy tại:');
  print(' -> Localhost:       http://localhost:${server.port}');
  print(' -> Android Emulator: http://10.0.2.2:${server.port}');
  print('======================================================');
}
