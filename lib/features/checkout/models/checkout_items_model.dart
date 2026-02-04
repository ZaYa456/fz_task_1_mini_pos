import 'package:hive/hive.dart';

part 'checkout_items_model.g.dart';

@HiveType(typeId: 3)
class CheckoutItem extends HiveObject {
  @HiveField(0)
  late int itemId; // Reference to the Item Box key

  @HiveField(1)
  late String itemName; // Snapshot the name in case item is deleted later

  @HiveField(2)
  late int quantity;

  @HiveField(3)
  late double priceAtSale; // Snapshot price (items change price, sales shouldn't)
}