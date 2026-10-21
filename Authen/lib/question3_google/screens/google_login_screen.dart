import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final _googleAuth = GoogleAuthService();
  final _clientIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSessionAndCallback();
  }

  Future<void> _checkSessionAndCallback() async {
    // 1. Kiểm tra xem trình duyệt có vừa được Google chuyển hướng về kèm token không (Web)
    final callbackSession = await _googleAuth.handleOAuthCallbackIfPresent();
    if (callbackSession != null && mounted) {
      setState(() {});
      return;
    }

    // 2. Nạp phiên đã lưu từ SharedPreferences
    final session = await _googleAuth.loadSavedSession();
    final savedClientId = await _googleAuth.getSavedClientId();
    if (savedClientId != null) {
      _clientIdController.text = savedClientId;
    }
    if (session != null && mounted) {
      setState(() {});
    }
  }

  Widget _buildGoogleLogo({double size = 24}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.7,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final clientId = _clientIdController.text.trim();

    // Chỉ bắt buộc Client ID nếu đang chạy trên nền tảng Web
    if (kIsWeb && clientId.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập Google Web Client ID vào ô bên dưới để Google mở cửa sổ đăng nhập trên Web.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (clientId.isNotEmpty) {
      await _googleAuth.saveClientId(clientId);
    }

    try {
      final session = await _googleAuth.signIn(clientId: clientId.isNotEmpty ? clientId : null);
      if (session != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thành công: ${session.email}'),
            backgroundColor: const Color(0xFF34A853),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _googleAuth.signOut();
    } catch (e) {
      debugPrint('Lỗi đăng xuất: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _googleAuth.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập Google'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: session == null
                    ? _buildLoginView(theme)
                    : _buildProfileView(theme, session),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(child: _buildGoogleLogo(size: 56)),
        const SizedBox(height: 20),
        Text(
          'Đăng nhập với Google',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'Xác thực tài khoản qua Google OAuth 2.0 Web'
              : 'Xác thực tài khoản qua Google Play Services',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Nút Sign in with Google chuẩn
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide(color: Colors.grey.shade400),
            backgroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _handleSignIn,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGoogleLogo(size: 22),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // Cấu hình Google Client ID chỉ hiển thị khi chạy trên WEB
        if (kIsWeb) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 18, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Cấu hình Google Client ID (Dành cho Web)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _clientIdController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Google Web Client ID (.apps.googleusercontent.com)',
                    hintText: 'Nhập Client ID để mở popup Google trên Web',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lấy từ Google Cloud Console (Credentials) hoặc Firebase Authentication.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('Mở trang Google Accounts trên trình duyệt'),
            onPressed: () => _googleAuth.openGoogleAccountsPage(),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileView(ThemeData theme, GoogleUserSession session) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.photoUrl != null && session.photoUrl!.isNotEmpty)
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(session.photoUrl!),
          )
        else
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF8D6E63),
            child: Text(
              session.displayName.isNotEmpty ? session.displayName[0].toUpperCase() : 'G',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          session.displayName,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          session.email,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Color(0xFF34A853)),
              SizedBox(width: 6),
              Text(
                'Đã xác thực Google',
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Thông tin phiên đăng nhập:', style: theme.textTheme.labelMedium),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            'UID: ${session.uid}\n'
            'Token: ${session.idToken.length > 40 ? '${session.idToken.substring(0, 40)}...' : session.idToken}\n'
            'Thời gian: ${session.signedInAt}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Đăng xuất'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _handleSignOut,
        ),
      ],
    );
  }
}
