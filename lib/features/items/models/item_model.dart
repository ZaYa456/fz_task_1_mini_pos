import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late double price;

  /// If true, you should check inventory quantity before selling.
  /// If false, it is a service or always-available item.
  @HiveField(2)
  bool isStockManaged = true;

  @HiveField(3)
  late DateTime registeredDate;

  // Optional: If you want to track actual stock count
  @HiveField(4)
  int stockQuantity = 0;

  @HiveField(5)
  String? barcode;

  @HiveField(6)
  String? category;

  // Add this helper method to your item_model.dart
  void updateFrom(Item other) {
    name = other.name;
    price = other.price;
    isStockManaged = other.isStockManaged;
    stockQuantity = other.stockQuantity;
    barcode = other.barcode;
    category = other.category;
    // We specifically DON'T update registeredDate or key here
  }
}
