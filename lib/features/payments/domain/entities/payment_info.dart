enum PaymentMethod { cash, card, other }

class PaymentInfo {
  final PaymentMethod method;
  final double amountPaid;
  final double totalDue;

  const PaymentInfo({
    required this.method,
    required this.amountPaid,
    required this.totalDue,
  });

  double get change => amountPaid - totalDue;
  bool get isValid => method == PaymentMethod.cash ? change >= 0 : true;

  PaymentInfo copyWith({
    PaymentMethod? method,
    double? amountPaid,
    double? totalDue,
  }) {
    return PaymentInfo(
      method: method ?? this.method,
      amountPaid: amountPaid ?? this.amountPaid,
      totalDue: totalDue ?? this.totalDue,
    );
  }
}
