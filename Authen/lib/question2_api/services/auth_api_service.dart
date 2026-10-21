import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthApiService {
  static const String _tokenKey = 'application_access_token';
  static const String _emailKey = 'user_email';
  static const String _nameKey = 'user_name';
  static const String _apiSourceKey = 'api_source_endpoint';

  /// Đăng nhập tài khoản qua REST API (Hỗ trợ DummyJSON & ReqRes)
  Future<AuthResponse> login(LoginRequest req) async {
    final identifier = req.email.trim();
    final password = req.password;

    // 1. Thử gọi API DummyJSON
    try {
      final username = identifier.contains('@') ? identifier.split('@').first : identifier;
      final dummyResponse = await http
          .post(
            Uri.parse('https://dummyjson.com/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            body: jsonEncode({
              'username': username,
              'password': password,
              'expiresInMins': 60,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (dummyResponse.statusCode == 200) {
        final data = jsonDecode(dummyResponse.body);
        final token = data['accessToken'] as String? ?? data['token'] as String;
        final fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        final email = data['email'] as String? ?? identifier;

        await saveSession(
          token: token,
          email: email,
          name: fullName.isNotEmpty ? fullName : username,
          apiEndpoint: 'DummyJSON API (200 OK)',
        );

        return AuthResponse(
          success: true,
          message: 'Đăng nhập thành công!',
          accessToken: token,
          email: email,
          fullName: fullName.isNotEmpty ? fullName : username,
        );
      }
    } catch (_) {
      // Tiếp tục thử ReqRes nếu DummyJSON không khớp
    }

    // 2. Thử gọi API ReqRes
    try {
      final reqresResponse = await http
          .post(
            Uri.parse('https://reqres.in/api/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            body: jsonEncode({
              'email': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (reqresResponse.statusCode == 200) {
        final data = jsonDecode(reqresResponse.body);
        final token = data['token'] as String;
        final name = identifier.split('@').first;

        await saveSession(
          token: token,
          email: identifier,
          name: name,
          apiEndpoint: 'ReqRes API (200 OK)',
        );

        return AuthResponse(
          success: true,
          message: 'Đăng nhập thành công!',
          accessToken: token,
          email: identifier,
          fullName: name,
        );
      } else {
        final errorData = jsonDecode(reqresResponse.body);
        throw Exception(errorData['error'] ?? 'Thông tin đăng nhập không chính xác.');
      }
    } catch (e) {
      if (e.toString().contains('không chính xác')) rethrow;
      throw Exception('Đăng nhập thất bại: Sai tài khoản hoặc mật khẩu.');
    }
  }

  /// Đăng ký tài khoản qua REST API (ReqRes API /register)
  Future<AuthResponse> register(RegisterRequest req) async {
    final response = await http
        .post(
          Uri.parse('https://reqres.in/api/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          body: jsonEncode({
            'email': req.email,
            'password': req.password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      return AuthResponse(
        success: true,
        message: 'Đăng ký tài khoản thành công!',
        accessToken: token,
        email: req.email,
        fullName: req.fullName,
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Đăng ký không thành công (Mã lỗi ${response.statusCode})');
    }
  }

  Future<void> saveSession({
    required String token,
    required String email,
    required String name,
    String apiEndpoint = 'REST API',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_apiSourceKey, apiEndpoint);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String?>> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'email': prefs.getString(_emailKey),
      'name': prefs.getString(_nameKey),
      'endpoint': prefs.getString(_apiSourceKey),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_apiSourceKey);
  }
}
