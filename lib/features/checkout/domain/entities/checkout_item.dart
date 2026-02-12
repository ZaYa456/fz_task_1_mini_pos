class CheckoutItem {
  final int itemId;
  final String itemName;
  final double priceAtSale;
  final int quantity;

  const CheckoutItem({
    required this.itemId,
    required this.itemName,
    required this.priceAtSale,
    required this.quantity,
  });

  double get total => priceAtSale * quantity;

  CheckoutItem copyWith({int? quantity}) {
    return CheckoutItem(
      itemId: itemId,
      itemName: itemName,
      priceAtSale: priceAtSale,
      quantity: quantity ?? this.quantity,
    );
  }
}
