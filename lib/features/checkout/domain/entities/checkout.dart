import 'checkout_item.dart';

enum CheckoutStatus { open, held, completed, cancelled }

class Checkout {
  final int id;
  final DateTime date;
  final List<CheckoutItem> items;
  final CheckoutStatus status;
  final double taxRate;

  const Checkout({
    required this.id,
    required this.date,
    required this.items,
    this.status = CheckoutStatus.open,
    this.taxRate = 0.0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * taxRate;
  double get totalAmount => subtotal + taxAmount;

  bool get isEmpty => items.isEmpty;

  Checkout copyWith({
    List<CheckoutItem>? items,
    CheckoutStatus? status,
    DateTime? date,
  }) {
    return Checkout(
      id: id,
      date: date ?? this.date,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate,
    );
  }
}
