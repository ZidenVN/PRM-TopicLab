import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/main.dart';

void main() {
  testWidgets('ChatbotPortalScreen loads all 3 questions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Kiểm tra tiêu đề Portal
    expect(find.text('Trợ lý Chatbot AI'), findsOneWidget);

    // Kiểm tra 3 thẻ của 3 câu hỏi
    expect(find.text('Mô phỏng Chatbot (DartPad)'), findsOneWidget);
    expect(find.text('Chatbot kết nối Groq API'), findsOneWidget);
    expect(find.text('Trợ lý Du lịch & Giữ ngữ cảnh'), findsOneWidget);
  });
}
