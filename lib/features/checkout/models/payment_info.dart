class PaymentInfo {
  final String method; // 'cash', 'card', 'other'
  final double amountPaid;
  final double totalDue;

  const PaymentInfo({
    required this.method,
    required this.amountPaid,
    required this.totalDue,
  });

  double get change => amountPaid - totalDue;
  bool get isValid => method == 'cash' ? change >= 0 : true;

  PaymentInfo copyWith({
    String? method,
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
