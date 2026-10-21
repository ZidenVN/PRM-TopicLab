import 'package:flutter_test/flutter_test.dart';
import 'package:payment_app/main.dart';

void main() {
  testWidgets('PaymentLabApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PaymentLabApp());
    expect(find.text('Thanh toán đơn hàng'), findsOneWidget);
  });
}
