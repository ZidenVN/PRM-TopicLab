import 'package:flutter/material.dart';
import 'question1_mock/mock_auth_dartpad.dart';
import 'question2_api/screens/api_login_screen.dart';
import 'question3_google/screens/google_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuthenLabApp());
}

class AuthenLabApp extends StatelessWidget {
  const AuthenLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xác thực & Quản lý phiên',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthenPortalScreen(),
    );
  }
}

class AuthenPortalScreen extends StatelessWidget {
  const AuthenPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic 4: Xác thực & Quản lý phiên'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xác thực người dùng & Quản lý phiên',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '3 mức độ xác thực: Mô phỏng form (DartPad) -> Đăng nhập qua REST API -> Đăng nhập bằng Google.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card Question 1
                  _buildQuestionCard(
                    context,
                    title: 'Câu 1: Mô phỏng xác thực (DartPad)',
                    subtitle: 'Xây dựng giao diện đăng nhập, kiểm tra dữ liệu đầu vào, giả lập phản hồi từ máy chủ và quản lý trạng thái đăng xuất.',
                    icon: Icons.code,
                    color: Colors.deepPurple,
                    targetScreen: const MockLoginScreen(),
                  ),
                  const SizedBox(height: 16),

                  // Card Question 2
                  _buildQuestionCard(
                    context,
                    title: 'Câu 2: Đăng nhập & Đăng ký qua REST API',
                    subtitle: 'Gửi yêu cầu xác thực qua API mạng, xử lý access token JWT, lưu phiên đăng nhập vào bộ nhớ máy và tự động điều hướng.',
                    icon: Icons.api,
                    color: Colors.indigo,
                    targetScreen: const ApiLoginScreen(),
                  ),
                  const SizedBox(height: 16),

                  // Card Question 3
                  _buildQuestionCard(
                    context,
                    title: 'Câu 3: Đăng nhập với Google',
                    subtitle: 'Tích hợp xác thực tài khoản Google bên thứ ba, đồng bộ thông tin hồ sơ người dùng và quản lý phiên an toàn.',
                    icon: Icons.g_mobiledata,
                    color: Colors.red.shade700,
                    targetScreen: const GoogleLoginScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget targetScreen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Xem chi tiết', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
