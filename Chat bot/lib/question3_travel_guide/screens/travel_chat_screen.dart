import 'package:flutter/material.dart';
import '../../core/ai_config.dart';
import '../services/travel_ai_service.dart';

class TravelChatScreen extends StatefulWidget {
  const TravelChatScreen({super.key});

  @override
  State<TravelChatScreen> createState() => _TravelChatScreenState();
}

class _TravelChatScreenState extends State<TravelChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TravelAiService _service = TravelAiService();

  final List<TravelMessage> _messages = [
    TravelMessage(
      role: 'assistant',
      content: 'Chào bạn! Mình là Trợ lý Du lịch. ✈️\n\n'
          'Mình có thể hỗ trợ bạn gợi ý địa điểm tham quan, ẩm thực đặc sản, phương tiện di chuyển và lịch trình khám phá.\n'
          'Cứ thoải mái hỏi mình về bất kỳ chuyến đi nào bạn đang ấp ủ nhé!',
      timestamp: DateTime.now(),
    ),
  ];

  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = TravelMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Gửi kèm toàn bộ lịch sử (Multi-turn conversation)
      final reply = await _service.sendTravelMessage(_messages, text);

      if (!mounted) return;
      setState(() {
        _messages.add(
          TravelMessage(
            role: 'assistant',
            content: reply,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      final cleanError = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add(
          TravelMessage(
            role: 'assistant',
            content: '❌ $cleanError',
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: AiConfig.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.teal),
            SizedBox(width: 8),
            Text('Cấu hình Groq API Key', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã Groq API Key (bắt đầu bằng `gsk_`):',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'gsk_...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await AiConfig.saveApiKey(keyController.text);
              if (!mounted) return;
              nav.pop();
              setState(() {});
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã cập nhật Groq API Key thành công!')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = AiConfig.hasValidKey;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Câu 3: Trợ Lý Du Lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(Icons.flight_takeoff, size: 12, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  'Tư vấn địa điểm, ẩm thực & lịch trình',
                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key, color: Colors.teal),
            tooltip: 'Cài đặt API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  TravelMessage(
                    role: 'assistant',
                    content: 'Đã làm mới cuộc trò chuyện. Bạn muốn tìm hiểu về địa điểm du lịch nào?',
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!hasKey)
              InkWell(
                onTap: _showApiKeyDialog,
                child: Container(
                  width: double.infinity,
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const Row(
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 16, color: Colors.brown),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chưa có API Key: Bấm vào đây để cấu hình và trải nghiệm Guardrails thật!',
                          style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.isUser;
                  final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.teal.shade600
                            : msg.isError
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                        border: Border.all(
                          color: msg.isError
                              ? Colors.red.shade300
                              : isUser
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                          bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.content,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : msg.isError
                                      ? Colors.red.shade900
                                      : Colors.black87,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trợ lý đang suy nghĩ và kiểm tra Guardrails...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.teal.shade700),
                    ),
                  ],
                ),
              ),

            // Khung nhập liệu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Hỏi về du lịch (hoặc thử câu bẫy ngoài lề)...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.teal),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: _isLoading ? null : _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
