import 'package:flutter_test/flutter_test.dart';
import 'package:authen_lab/main.dart';

void main() {
  testWidgets('AuthenLabApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuthenLabApp());
    expect(find.text('Topic 4: Xác thực & Quản lý phiên'), findsOneWidget);
    expect(find.text('Câu 1: Mô phỏng xác thực (DartPad)'), findsOneWidget);
    expect(find.text('Câu 2: Đăng nhập & Đăng ký qua REST API'), findsOneWidget);
    expect(find.text('Câu 3: Đăng nhập với Google'), findsOneWidget);
  });
}
