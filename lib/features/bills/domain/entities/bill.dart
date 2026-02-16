/// Domain entity representing a completed bill/checkout
class Bill {
  final int id;
  final DateTime date;
  final double totalAmount;
  final List<BillItem> items;

  const Bill({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.items,
  });

  Bill copyWith({
    int? id,
    DateTime? date,
    double? totalAmount,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id ?? this.id,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
    );
  }
}

/// Domain entity representing an item in a bill
class BillItem {
  final String itemName;
  final int quantity;
  final double priceAtSale;
  final double subtotal;

  const BillItem({
    required this.itemName,
    required this.quantity,
    required this.priceAtSale,
    required this.subtotal,
  });

  BillItem copyWith({
    String? itemName,
    int? quantity,
    double? priceAtSale,
    double? subtotal,
  }) {
    return BillItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
