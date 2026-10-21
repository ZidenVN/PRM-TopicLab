import 'package:flutter/material.dart';
import '../../core/ai_config.dart';
import '../services/basic_ai_service.dart';

class BasicChatScreen extends StatefulWidget {
  const BasicChatScreen({super.key});

  @override
  State<BasicChatScreen> createState() => _BasicChatScreenState();
}

class _BasicChatScreenState extends State<BasicChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BasicAiService _service = BasicAiService();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Chào bạn! Mình là AI kết nối qua Groq API. Cứ hỏi mình bất kỳ điều gì nhé, từ lập trình Flutter đến chuyện trò vui vẻ!',
      'time': DateTime.now(),
    }
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

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': reply,
          'time': DateTime.now(),
        });
      });
    } catch (e) {
      if (!mounted) return;
      final cleanError = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add({
          'isUser': false,
          'text': '❌ $cleanError',
          'isError': true,
          'time': DateTime.now(),
        });
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
            Icon(Icons.vpn_key, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Cấu hình Groq API Key', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lấy API Key miễn phí tại https://console.groq.com/keys và dán vào đây:',
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
    final theme = Theme.of(context);
    final hasKey = AiConfig.hasValidKey;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Câu 2: Basic Chatbot AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(
                  hasKey ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 13,
                  color: hasKey ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  hasKey ? 'Groq Cloud (Online)' : 'Chưa nhập API Key',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasKey ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Cài đặt API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Xóa lịch sử',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'isUser': false,
                  'text': 'Đã làm mới cuộc trò chuyện. Hãy nhập câu hỏi cho AI nhé!',
                  'time': DateTime.now(),
                });
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
                  color: Colors.amber.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bấm vào đây để nhập Groq API Key và gọi AI thật!',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isError = msg['isError'] == true;
                  final time = msg['time'] as DateTime;
                  final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.colorScheme.primary
                            : isError
                                ? Colors.red.shade50
                                : Colors.grey.shade200,
                        border: isError ? Border.all(color: Colors.red.shade300) : null,
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
                            msg['text'] as String,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : isError
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI đang kết nối máy chủ Groq...',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.text,
                      enableSuggestions: true,
                      autocorrect: true,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Hỏi bất kỳ điều gì...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
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
