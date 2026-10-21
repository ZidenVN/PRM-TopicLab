import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================================
// CÂU 1: MÔ PHỎNG TRỢ LÝ CHATBOT AI TRÊN DARTPAD
// File này độc lập 100%, có thể copy toàn bộ nội dung để chạy trực tiếp trên:
// https://dartpad.dev (Chọn chế độ Flutter)
// Các tính năng:
// 1. Model ChatMessage (text, isUser, timestamp)
// 2. Chat Bubble (Bong bóng chat phân biệt User và AI)
// 3. Auto-scroll xuống tin nhắn mới nhất bằng ScrollController
// 4. Trạng thái "AI đang suy nghĩ..." (Typing indicator)
// 5. MockAiService với Bộ tri thức đàm thoại phong phú (Local NLP Rule-based Dataset),
//    phản hồi tự nhiên, duyên dáng, trả lời đầy đủ các câu hỏi đời sống và kiến thức Flutter.
// ============================================================================

void main() {
  runApp(const MockChatApp());
}

class MockChatApp extends StatelessWidget {
  const MockChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Câu 1: Mock Chatbot AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MockChatScreen(),
    );
  }
}

/// Model dữ liệu tin nhắn theo chuẩn yêu cầu Question 1
class MockChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const MockChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Lớp đại diện cho một nhóm ý định (Intent) trong Bộ dữ liệu đàm thoại
class _MockIntent {
  final List<String> keywords;
  final List<String> responses;

  const _MockIntent({
    required this.keywords,
    required this.responses,
  });

  bool matches(String input) {
    return keywords.any((kw) => input.contains(kw));
  }
}

/// Dịch vụ giả lập phản hồi AI với bộ tri thức phong phú, tự nhiên, không bị máy móc
class MockAiService {
  final Random _random = Random();

  /// Bộ dữ liệu đàm thoại nội bộ (Local Knowledge Base Dataset)
  static const List<_MockIntent> _dataset = [
    // 1. Chào hỏi thân thiện
    _MockIntent(
      keywords: ['chào', 'hello', 'hi ', 'hi!', 'hey', 'alo', 'hế lô', 'good morning', 'buổi sáng', 'buổi tối', 'yo'],
      responses: [
        'Chào bạn nè! Rất vui được gặp bạn hôm nay. Hôm nay bạn học tập hoặc làm đồ án thế nào rồi? Cần mình trợ giúp gì không nè? 😊',
        'Hế lô bạn hiền! Chúc bạn một ngày tràn đầy năng lượng nha. Bạn đang vướng chỗ nào trong bài lab Flutter hả, cứ hỏi mình nhé!',
        'Chào người bạn chăm chỉ! Mình đã sẵn sàng hỗ trợ bạn rồi đây. Hôm nay cùng nhau chinh phục Flutter nhé! ✨',
      ],
    ),

    // 2. Hỏi thăm danh tính, nguồn gốc
    _MockIntent(
      keywords: ['bạn là ai', 'tên gì', 'tên là gì', 'ai tạo ra', 'giới thiệu', 'who are you', 'bạn là cái gì'],
      responses: [
        'Mình là AI Assistant 🤖 — Trợ lý ảo được viết bằng Flutter! Mình có thể giải thích các khái niệm Flutter, hỗ trợ bạn ôn bài, hoặc cùng bạn trò chuyện khi đang code mệt mỏi đấy.',
        'Chào bạn! Mình là Trợ lý AI ở Câu 1 (chạy mô phỏng trên DartPad). Mình sinh ra từ những dòng code Dart chuẩn chỉnh và rất sẵn lòng đồng hành cùng bạn!',
      ],
    ),

    // 3. Hỏi thăm sức khỏe, cảm xúc
    _MockIntent(
      keywords: ['khỏe không', 'thế nào rồi', 'dạo này sao', 'how are you', 'ổn không'],
      responses: [
        'Mình chạy bằng điện và code nên lúc nào cũng tràn trề 100% năng lượng! Còn bạn thì sao, hôm nay chạy code có mượt không hay lại bị con bug nào hành thế? 😄',
        'Mình vẫn khỏe và luôn sẵn sàng hỗ trợ bạn nè! Hy vọng hôm nay bạn học được nhiều widget hay ho và không bị tràn bộ nhớ nha!',
      ],
    ),

    // 4. Ăn uống, sinh hoạt
    _MockIntent(
      keywords: ['ăn cơm chưa', 'ăn gì chưa', 'ăn chưa', 'đói bụng', 'uống nước', 'ăn tối'],
      responses: [
        'Mình chỉ "ăn" dữ liệu JSON và "uống" pin máy tính thôi hà! Nhưng bạn là người thật nên nhớ ăn uống đúng giờ nhé, đừng vì cày deadline mà nhịn ăn nha, đau bao tử đó! 🍲',
        'Đang đói bụng hả bạn? Nghỉ tay 1 chút xuống làm cốc trà sữa hoặc bánh ngọt nạp tí đường rồi quay lại code tiếp cho tỉnh táo nè! 🧋',
      ],
    ),

    // 5. Cảm ơn
    _MockIntent(
      keywords: ['cảm ơn', 'thank', 'cmon', 'cam on', 'tks', 'thank you', 'tuyệt vời', 'giỏi quá', 'hay quá'],
      responses: [
        'Không có chi nè! Được hỗ trợ bạn là niềm vui lớn nhất của mình rồi. Chúc bạn làm bài lab điểm cao chót vót nhé! ❤️',
        'Hihi, cảm ơn bạn đã khen nha! Cần gì thêm cứ nhắn mình, mình luôn ở đây mà. ✨',
      ],
    ),

    // 6. Tạm biệt
    _MockIntent(
      keywords: ['tạm biệt', 'bye', 'goodbye', 'ngủ ngon', 'đi ngủ', 'hẹn gặp lại', 'off đây'],
      responses: [
        'Tạm biệt bạn nhé! Chúc bạn ngủ ngon hoặc có một buổi học thật hiệu quả. Hẹn gặp lại bạn lần sau nha! 👋',
        'Bye bye bạn! Chúc bạn bảo vệ đồ án và bài lab đạt điểm 10 tròn trĩnh nhé!',
      ],
    ),

    // 7. Tâm trạng căng thẳng, nản, deadline
    _MockIntent(
      keywords: ['mệt', 'buồn ngủ', 'nản', 'lười', 'stress', 'áp lực', 'deadline', 'sợ rớt', 'rớt môn', 'qua môn'],
      responses: [
        'Thương bạn ghê! Học IT nhiều lúc vừa mệt vừa căng thẳng vì bug. Đứng dậy vươn vai, hít thở thật sâu rồi uống một ngụm nước mát đi bạn. Bạn đã đi được một chặng đường rất xa rồi, vững tin lên nào! 💪',
        'Chăm chỉ luyện các Topic Lab thế này thì qua môn điểm A, A+ luôn chứ sợ gì rớt! Tự tin lên nhé, bạn đang làm rất tốt đó! 🔥',
      ],
    ),

    // 8. Lập trình di động & Công nghệ
    _MockIntent(
      keywords: ['lập trình', 'code', 'developer', 'dev', 'mobile app'],
      responses: [
        'Lập trình di động là một hành trình thú vị với nhiều công nghệ hiện đại. Hãy cùng rèn luyện tư duy và xây dựng những ứng dụng tuyệt vời nhé! 💻🚀',
        'Nghề dev luôn đầy thử thách nhưng cũng cực kỳ thú vị. Chúc bạn luôn giữ vững ngọn lửa đam mê công nghệ nhé!',
      ],
    ),

    // 9. Flutter là gì?
    _MockIntent(
      keywords: ['flutter là gì', 'khái niệm flutter', 'flutter la gi', 'tìm hiểu flutter'],
      responses: [
        'Flutter là bộ công cụ phát triển giao diện (UI Toolkit) mã nguồn mở siêu đỉnh của Google. Điểm mạnh nhất của nó là "viết code 1 lần bằng Dart nhưng chạy mượt mà trên cả Android, iOS, Web, Windows và macOS" với tốc độ khung hình 60-120 FPS!',
      ],
    ),

    // 10. Dart là gì?
    _MockIntent(
      keywords: ['dart là gì', 'ngôn ngữ dart', 'dart la gi'],
      responses: [
        'Dart là ngôn ngữ lập trình hướng đối tượng do Google tạo ra, dùng làm nền tảng cho Flutter. Dart có tính năng gõ kiểu an toàn (Sound Null Safety) và hỗ trợ cả biên dịch JIT (giúp Hot Reload tức thì khi debug) lẫn AOT (biên dịch ra mã máy siêu tốc khi phát hành app)!',
      ],
    ),

    // 11. StatelessWidget vs StatefulWidget
    _MockIntent(
      keywords: ['stateless', 'stateful', 'khác nhau giữa stateless', 'so sánh stateless'],
      responses: [
        'Khác biệt cốt lõi khi bảo vệ lab nè bạn:\n'
        '• StatelessWidget: Dành cho giao diện bất biến (tĩnh), không thay đổi theo thời gian (như Icon, Text cố định).\n'
        '• StatefulWidget: Dành cho giao diện động, có thể thay đổi dữ liệu và vẽ lại màn hình theo thời gian khi người dùng tương tác nhờ gọi hàm setState()!',
      ],
    ),

    // 12. Widget là gì?
    _MockIntent(
      keywords: ['widget là gì', 'khái niệm widget', 'widget la gi'],
      responses: [
        'Trong Flutter có triết lý nổi tiếng: "Everything is a Widget!" Mọi thứ hiển thị trên màn hình — từ văn bản (Text), nút bấm (Button), cách bố cục (Row, Column, Stack) cho đến căn lề (Padding) và màu nền — tất cả đều là các widget được lồng ghép như các khối Lego!',
      ],
    ),

    // 13. Hot Reload là gì?
    _MockIntent(
      keywords: ['hot reload', 'hot restart'],
      responses: [
        'Hot Reload là tính năng "thần thánh" của Flutter! Khi bạn chỉnh sửa mã nguồn và lưu file (Ctrl + S), thay đổi sẽ hiển thị lên màn hình ngay trong chưa đầy 1 giây mà KHÔNG làm mất trạng thái (state) hiện tại của ứng dụng. Nhờ đó tốc độ phát triển app tăng gấp nhiều lần!',
      ],
    ),

    // 14. BuildContext là gì?
    _MockIntent(
      keywords: ['buildcontext', 'context là gì', 'build context'],
      responses: [
        'BuildContext chính là "tọa độ định vị GPS" của một widget trong cây Widget Tree! Nhờ có nó mà Flutter biết widget này đang nằm ở đâu để tìm kiếm Theme, MediaQuery (lấy kích thước màn hình) hoặc Navigator (để chuyển trang).',
      ],
    ),

    // 15. setState là gì?
    _MockIntent(
      keywords: ['setstate', 'hàm setstate', 'khi nào dùng setstate'],
      responses: [
        'setState() là hàm thông báo cho Flutter Framework biết: "Dữ liệu bên trong State vừa thay đổi rồi, hãy gọi lại hàm build() để vẽ lại giao diện mới cho người dùng xem đi!".',
      ],
    ),

    // 16. Các chủ đề thực hành (Topic Lab)
    _MockIntent(
      keywords: ['topic', 'chủ đề', 'lab', 'thực hành'],
      responses: [
        'Hệ thống gồm các chủ đề thực hành: Topic 1: Database, Topic 2: Bản đồ Map, Topic 3: Thanh toán Payment, Topic 4: Authentication, và Topic 6: Chatbot AI!',
      ],
    ),

    // 17. Hỏi về Câu 2 & Câu 3
    _MockIntent(
      keywords: ['câu 2', 'câu 3', 'groq', 'llama', 'api thật', 'du lịch'],
      responses: [
        'Ở Câu 1 này mình dùng bộ tri thức mô phỏng trên DartPad. Nếu bạn muốn trò chuyện tự do cùng mô hình ngôn ngữ lớn LLaMA-3.3-70B thật qua mạng, hoặc trải nghiệm Trợ lý Du lịch có Guardrails khống chế chủ đề, hãy quay lại Portal Menu chọn Câu 2 hoặc Câu 3 nhé!',
      ],
    ),
  ];

  /// Danh sách các phản hồi dự phòng tự nhiên, duyên dáng khi không khớp từ khóa
  static const List<String> _fallbackReplies = [
    'Câu hỏi này thú vị ghê! Nhưng vì mình đang ở Câu 1 (mô phỏng offline trên DartPad với bộ quy tắc cục bộ) nên vốn từ của mình chưa bao quát hết được. Bạn thử hỏi mình về Flutter, Dart, Widget, hoặc chuyển sang Câu 2 để hỏi AI LLaMA-3 thật xem sao nhé! 😊',
    'U là trời, câu này nằm ngoài danh mục trả lời nhanh của mình ở bản demo rồi nè! Bạn thử hỏi về các khái niệm Flutter như "Stateful là gì?", "Hot Reload là gì?" xem, mình giải thích vanh vách luôn á!',
    'Mình chưa được nạp dữ liệu cho câu hỏi này ở Câu 1 rồi. Nhưng bạn yên tâm, nếu bạn mở Câu 2 hoặc Câu 3 kết nối Groq Cloud API, mô hình LLaMA-3.3 sẽ trả lời cực kỳ thông minh luôn đó!',
    'Một góc nhìn mới mẻ ghê! Ở Câu 1 này mình là trợ lý chạy bằng code thuần Dart không cần mạng. Bạn hãy thử hỏi những câu về học tập hoặc các widget Flutter xem sao nhé!',
  ];

  Future<String> getReply(String prompt) async {
    // 1. Giả lập độ trễ mạng tự nhiên (800ms)
    await Future.delayed(const Duration(milliseconds: 800));

    final query = prompt.trim().toLowerCase();
    if (query.isEmpty) {
      return 'Bạn hãy nhập gì đó vào khung chat nhé!';
    }

    // 2. Tìm kiếm trong Bộ dữ liệu đàm thoại (Local Knowledge Base)
    for (final intent in _dataset) {
      if (intent.matches(query)) {
        final options = intent.responses;
        return options[_random.nextInt(options.length)];
      }
    }

    // 3. Nếu không khớp từ khóa, trả về câu phản hồi tự nhiên ngẫu nhiên
    return _fallbackReplies[_random.nextInt(_fallbackReplies.length)];
  }
}

class MockChatScreen extends StatefulWidget {
  const MockChatScreen({super.key});

  @override
  State<MockChatScreen> createState() => _MockChatScreenState();
}

class _MockChatScreenState extends State<MockChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MockAiService _mockService = MockAiService();

  final List<MockChatMessage> _messages = [
    MockChatMessage(
      text: 'Chào bạn! Mình là Trợ lý AI ở Câu 1 (mô phỏng trên DartPad). ✨\n\n'
          'Bạn có thể hỏi mình những câu giao tiếp hàng ngày, hoặc các khái niệm Flutter như:\n'
          '• Flutter là gì?\n'
          '• StatefulWidget khác gì StatelessWidget?\n'
          '• Hot Reload hay BuildContext dùng để làm gì?\n'
          '• Hoặc trò chuyện vu vơ giải tỏa căng thẳng cũng được nè! 😊',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isAiTyping = false;

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

  Future<void> _handleSendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isAiTyping) return;

    // 1. Thêm tin nhắn của User vào danh sách
    setState(() {
      _messages.add(
        MockChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isAiTyping = true;
    });

    if (presetText == null) {
      _textController.clear();
    }
    _scrollToBottom();

    // 2. Gọi Mock Service
    try {
      final reply = await _mockService.getReply(text);

      if (!mounted) return;
      setState(() {
        _messages.add(
          MockChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MockChatMessage(
            text: 'Đã xảy ra lỗi: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isAiTyping = false);
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Câu 1: Mock Chatbot AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Chạy độc lập trên DartPad (Không cần API Key)', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới hội thoại',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  MockChatMessage(
                    text: 'Chào bạn! Mình là Trợ lý AI ở Câu 1 (mô phỏng trên DartPad). ✨\n\n'
                        'Bạn có thể hỏi mình những câu giao tiếp hàng ngày, hoặc các khái niệm Flutter như:\n'
                        '• Flutter là gì?\n'
                        '• StatefulWidget khác gì StatelessWidget?\n'
                        '• Hot Reload hay BuildContext dùng để làm gì?\n'
                        '• Hoặc trò chuyện vu vơ giải tỏa căng thẳng cũng được nè! 😊',
                    isUser: false,
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
            // Thanh gợi ý câu hỏi nhanh (Quick prompts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.indigo.shade50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Gợi ý: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    _buildQuickChip('👋 Chào bạn'),
                    const SizedBox(width: 6),
                    _buildQuickChip('📱 Flutter là gì?'),
                    const SizedBox(width: 6),
                    _buildQuickChip('⚖️ Stateful vs Stateless?'),
                    const SizedBox(width: 6),
                    _buildQuickChip('⚡ Hot Reload là gì?'),
                    const SizedBox(width: 6),
                    _buildQuickChip('🍲 Ăn cơm chưa?'),
                    const SizedBox(width: 6),
                    _buildQuickChip('💪 Đang mệt quá'),
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
                  return _buildChatBubble(msg, theme);
                },
              ),
            ),

            // Trạng thái "AI đang suy nghĩ..."
            if (_isAiTyping)
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
                      'AI đang suy nghĩ...',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

            // Khung nhập liệu ở đáy màn hình
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.indigo),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.indigo.shade200),
      padding: EdgeInsets.zero,
      onPressed: _isAiTyping
          ? null
          : () => _handleSendMessage(label.replaceAll(RegExp(r'^[^\s]+\s'), '')),
    );
  }

  Widget _buildChatBubble(MockChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.38,
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
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isAiTyping,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn cho AI...',
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
            onPressed: _isAiTyping ? null : () => _handleSendMessage(),
          ),
        ],
      ),
    );
  }
}
