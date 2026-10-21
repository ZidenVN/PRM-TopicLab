enum PaymentStatus { pending, success, failed }

class Payment {
  final String id;
  final String orderId;
  final int amount;
  final PaymentStatus status;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        amount: json['amount'] as int,
        status: switch (json['status']) {
          'SUCCESS' => PaymentStatus.success,
          'FAILED' => PaymentStatus.failed,
          _ => PaymentStatus.pending,
        },
      );
}
