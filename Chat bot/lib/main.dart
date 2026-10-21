import 'package:flutter/material.dart';
import 'core/ai_config.dart';
import 'question1_mock/mock_chat_dartpad.dart';
import 'question2_basic_api/screens/basic_chat_screen.dart';
import 'question3_travel_guide/screens/travel_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AiConfig.loadApiKey();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topic 6: Chatbot AI Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatbotPortalScreen(),
        '/q1': (context) => const MockChatScreen(),
        '/q2': (context) => const BasicChatScreen(),
        '/q3': (context) => const TravelChatScreen(),
      },
    );
  }
}

class ChatbotPortalScreen extends StatefulWidget {
  const ChatbotPortalScreen({super.key});

  @override
  State<ChatbotPortalScreen> createState() => _ChatbotPortalScreenState();
}

class _ChatbotPortalScreenState extends State<ChatbotPortalScreen> {
  void _openApiKeyDialog() {
    final keyController = TextEditingController(text: AiConfig.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Cấu hình Groq API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lấy API Key miễn phí từ Groq Cloud (chỉ mất 1 phút):\n'
              '1. Truy cập https://console.groq.com/keys\n'
              '2. Bấm "Create API Key" và copy mã `gsk_...`\n'
              '3. Dán vào ô bên dưới rồi bấm Lưu:',
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'gsk_...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          if (AiConfig.hasValidKey)
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                await AiConfig.clearApiKey();
                if (!mounted) return;
                nav.pop();
                setState(() {});
              },
              child: const Text('Xóa Key', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await AiConfig.saveApiKey(keyController.text);
              if (!mounted) return;
              nav.pop();
              setState(() {});
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã cập nhật Groq API Key!')),
              );
            },
            child: const Text('Lưu Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = AiConfig.hasValidKey;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trợ lý Chatbot AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Topic 6 - AI Assistant', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Cài đặt Groq API Key',
            onPressed: _openApiKeyDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner trạng thái API Key
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasKey ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasKey ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasKey ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: hasKey ? const Color(0xFF059669) : const Color(0xFFD97706),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasKey ? 'Đã kết nối Groq API' : 'Chưa cấu hình API Key',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasKey ? const Color(0xFF065F46) : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasKey
                              ? 'Mô hình: Qwen 3.8'
                              : 'Bấm biểu tượng 🔑 để nhập API Key.',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasKey ? const Color(0xFF047857) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openApiKeyDialog,
                    child: Text(hasKey ? 'Đổi Key' : 'Nhập Key'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'DANH SÁCH BÀI TẬP',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.black54),
            ),
            const SizedBox(height: 14),

            // Card 1
            _buildTopicCard(
              context,
              badge: 'CÂU 1',
              badgeColor: Colors.blue,
              title: 'Mô phỏng Chatbot (DartPad)',
              description: 'Giao diện chat bong bóng, tự động cuộn và phản hồi mô phỏng (chạy trực tiếp trên DartPad).',
              icon: Icons.code,
              iconColor: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/q1'),
            ),
            const SizedBox(height: 16),

            // Card 2
            _buildTopicCard(
              context,
              badge: 'CÂU 2',
              badgeColor: Colors.purple,
              title: 'Chatbot kết nối Groq API',
              description: 'Gửi nhận tin nhắn qua Groq Cloud (HTTP POST), xác thực Bearer token và xử lý dữ liệu JSON.',
              icon: Icons.cloud_done_outlined,
              iconColor: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/q2'),
            ),
            const SizedBox(height: 16),

            // Card 3
            _buildTopicCard(
              context,
              badge: 'CÂU 3',
              badgeColor: Colors.teal,
              title: 'Trợ lý Du lịch & Giữ ngữ cảnh',
              description: 'Giới hạn chủ đề du lịch (từ chối câu hỏi ngoài lề), ghi nhớ ngữ cảnh hội thoại và kiểm soát lỗi mạng.',
              icon: Icons.flight_takeoff,
              iconColor: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/q3'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(icon, color: iconColor, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Vào xem',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: badgeColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
