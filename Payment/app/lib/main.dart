import 'package:flutter/material.dart';
import 'screens/checkout_screen.dart';

void main() => runApp(const PaymentLabApp());

class PaymentLabApp extends StatelessWidget {
  const PaymentLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Gateway Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CheckoutScreen(),
    );
  }
}
