class Item {
  final int id;
  final String name;
  final double price;
  final bool isStockManaged;
  int stockQuantity;
  final String? barcode;
  final String? category;
  final DateTime registeredDate;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.isStockManaged,
    required this.stockQuantity,
    required this.registeredDate,
    this.barcode,
    this.category,
  });

  Item copyWith({
    int? id,
    String? name,
    double? price,
    bool? isStockManaged,
    int? stockQuantity,
    String? barcode,
    String? category,
    DateTime? registeredDate,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isStockManaged: isStockManaged ?? this.isStockManaged,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      registeredDate: registeredDate ?? this.registeredDate,
    );
  }
}
