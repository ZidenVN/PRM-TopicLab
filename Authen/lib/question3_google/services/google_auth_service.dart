import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleUserSession {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String idToken;
  final DateTime signedInAt;

  GoogleUserSession({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.idToken,
    required this.signedInAt,
  });
}

class GoogleAuthService {
  static const String _keyToken = 'google_id_token';
  static const String _keyEmail = 'google_email';
  static const String _keyName = 'google_name';
  static const String _keyPhoto = 'google_photo';
  static const String _keyUid = 'google_uid';
  static const String _keyTime = 'google_signed_in_at';
  static const String _keyClientId = 'saved_google_client_id';

  GoogleUserSession? _currentSession;
  GoogleUserSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;

  static const String defaultServerClientId =
      '734654062477-t9mu5r8nu1oi7uus8rrv34qb0qv2qrhm.apps.googleusercontent.com';

  static bool _hasInitializedOnce = false;

  Future<void> initGoogle({String? clientId, String? serverClientId}) async {
    if (_hasInitializedOnce) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId ?? defaultServerClientId,
      );
      _hasInitializedOnce = true;
    } catch (e) {
      _hasInitializedOnce = true;
      debugPrint('GoogleSignIn initialize: $e');
    }
  }

  Future<String?> getSavedClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyClientId);
  }

  Future<void> saveClientId(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClientId, clientId.trim());
  }

  /// Nạp phiên đăng nhập Google đã lưu trong SharedPreferences
  Future<GoogleUserSession?> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final email = prefs.getString(_keyEmail);
    final name = prefs.getString(_keyName);
    final photo = prefs.getString(_keyPhoto);
    final uid = prefs.getString(_keyUid);
    final timeStr = prefs.getString(_keyTime);

    if (token != null && email != null && name != null) {
      _currentSession = GoogleUserSession(
        uid: uid ?? 'google_uid_${DateTime.now().millisecondsSinceEpoch}',
        displayName: name,
        email: email,
        photoUrl: photo,
        idToken: token,
        signedInAt: timeStr != null ? (DateTime.tryParse(timeStr) ?? DateTime.now()) : DateTime.now(),
      );
      return _currentSession;
    }
    return null;
  }

  /// Kiểm tra xem URL có chứa token trả về từ Google OAuth sau khi đăng nhập không (Dành cho Web)
  Future<GoogleUserSession?> handleOAuthCallbackIfPresent() async {
    if (!kIsWeb) return null;

    final fragment = Uri.base.fragment;
    if (fragment.isEmpty || !fragment.contains('access_token=')) {
      return null;
    }

    try {
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];

      if (accessToken != null && accessToken.isNotEmpty) {
        final userinfoResponse = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (userinfoResponse.statusCode == 200) {
          final data = jsonDecode(userinfoResponse.body) as Map<String, dynamic>;
          final email = data['email'] as String? ?? 'user@gmail.com';
          final name = data['name'] as String? ?? email.split('@').first;
          final picture = data['picture'] as String?;
          final sub = data['sub'] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}';
          final timestamp = DateTime.now();

          final session = GoogleUserSession(
            uid: sub,
            displayName: name,
            email: email,
            photoUrl: picture,
            idToken: accessToken,
            signedInAt: timestamp,
          );

          _currentSession = session;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyToken, accessToken);
          await prefs.setString(_keyEmail, email);
          await prefs.setString(_keyName, name);
          if (picture != null) await prefs.setString(_keyPhoto, picture);
          await prefs.setString(_keyUid, sub);
          await prefs.setString(_keyTime, timestamp.toIso8601String());

          return session;
        }
      }
    } catch (e) {
      debugPrint('Lỗi xử lý callback Google OAuth: $e');
    }
    return null;
  }

  /// Mở cửa sổ đăng nhập Google thật
  Future<GoogleUserSession?> signIn({String? clientId}) async {
    if (kIsWeb) {
      // 1. TRÊN WEB: Cần Client ID để mở trang OAuth redirect
      final activeClientId = clientId?.trim().isNotEmpty == true
          ? clientId!.trim()
          : await getSavedClientId();

      if (activeClientId == null || activeClientId.isEmpty) {
        throw Exception(
          'Vui lòng nhập Google Web Client ID ở mục cấu hình bên dưới để kết nối với Google OAuth.',
        );
      }

      final redirectUri = Uri.base.origin;
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': activeClientId,
        'redirect_uri': redirectUri,
        'response_type': 'token',
        'scope': 'email profile openid',
        'prompt': 'select_account',
      });

      final launched = await launchUrl(authUri, webOnlyWindowName: '_self');
      if (!launched) {
        throw Exception('Trình duyệt không thể mở đường dẫn xác thực Google.');
      }
      return null;
    } else {
      // 2. TRÊN ANDROID / MOBILE:
      // Gọi trực tiếp Google Play Services qua plugin google_sign_in!
      // Không cần nhập Web Client ID!
      await initGoogle();

      try {
        final account = await GoogleSignIn.instance.authenticate();
        final auth = account.authentication;
        final timestamp = DateTime.now();

        final session = GoogleUserSession(
          uid: account.id,
          displayName: account.displayName ?? account.email.split('@').first,
          email: account.email,
          photoUrl: account.photoUrl,
          idToken: auth.idToken ?? 'oauth_token_${timestamp.millisecondsSinceEpoch}',
          signedInAt: timestamp,
        );

        _currentSession = session;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, session.idToken);
        await prefs.setString(_keyEmail, session.email);
        await prefs.setString(_keyName, session.displayName);
        if (session.photoUrl != null) {
          await prefs.setString(_keyPhoto, session.photoUrl!);
        }
        await prefs.setString(_keyUid, session.uid);
        await prefs.setString(_keyTime, session.signedInAt.toIso8601String());

        return session;
      } catch (e) {
        debugPrint('Android Google Sign In Error: $e');
        if (e.toString().contains('ApiException: 10') || e.toString().contains('code: 10')) {
          throw Exception(
            'Lỗi Google Play Services (Mã 10):\n'
            'Máy ảo Android cần có tài khoản Google trong Cài đặt, hoặc cần liên kết mã SHA-1 của máy trên Firebase/Google Cloud.',
          );
        }
        rethrow;
      }
    }
  }

  /// Mở trang tài khoản Google trực tiếp trên trình duyệt
  Future<void> openGoogleAccountsPage() async {
    final uri = Uri.parse('https://accounts.google.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Đăng xuất Google và xóa sạch phiên trong bộ nhớ
  Future<void> signOut() async {
    _currentSession = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyName);
      await prefs.remove(_keyPhoto);
      await prefs.remove(_keyUid);
      await prefs.remove(_keyTime);
    } catch (e) {
      debugPrint('Lỗi xóa SharedPreferences: $e');
    }

    try {
      await GoogleSignIn.instance.signOut().timeout(const Duration(milliseconds: 300));
    } catch (_) {}
  }
}
