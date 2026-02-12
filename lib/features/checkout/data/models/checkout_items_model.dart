import 'package:fz_task_1/features/checkout/domain/entities/checkout_item.dart';
import 'package:hive/hive.dart';

part 'checkout_items_model.g.dart';

@HiveType(typeId: 3)
class CheckoutItemModel extends HiveObject {
  @HiveField(0)
  late int itemId;

  @HiveField(1)
  late String itemName;

  @HiveField(2)
  late int quantity;

  @HiveField(3)
  late double priceAtSale;

  // Converts Hive Model to Domain Entity
  CheckoutItem toEntity() {
    return CheckoutItem(
      itemId: itemId,
      itemName: itemName,
      priceAtSale: priceAtSale,
      quantity: quantity,
    );
  }

  // Converts Domain Entity to Hive Model
  static CheckoutItemModel fromEntity(CheckoutItem entity) {
    return CheckoutItemModel()
      ..itemId = entity.itemId
      ..itemName = entity.itemName
      ..priceAtSale = entity.priceAtSale
      ..quantity = entity.quantity;
  }
}
