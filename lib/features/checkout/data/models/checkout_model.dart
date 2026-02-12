import 'package:fz_task_1/features/checkout/domain/entities/checkout.dart';
import 'package:hive/hive.dart';
import 'checkout_items_model.dart';

part 'checkout_model.g.dart';

@HiveType(typeId: 2)
class CheckoutModel extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late double totalAmount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late List<CheckoutItemModel> items;

  @HiveField(4)
  late String status;

  // Map Hive model to Domain Entity
  Checkout toEntity() {
    return Checkout(
      id: id,
      date: date,
      items: items.map((m) => m.toEntity()).toList(),
      status: _parseStatus(status),
    );
  }

  // Map Domain Entity to Hive Model
  static CheckoutModel fromEntity(Checkout entity) {
    return CheckoutModel()
      ..id = entity.id
      ..date = entity.date
      ..items =
          entity.items.map((e) => CheckoutItemModel.fromEntity(e)).toList()
      ..totalAmount = entity.totalAmount
      ..status = _serializeStatus(entity.status);
  }

  static CheckoutStatus _parseStatus(String status) {
    switch (status) {
      case 'open':
        return CheckoutStatus.open;
      case 'held':
        return CheckoutStatus.held;
      case 'completed':
        return CheckoutStatus.completed;
      case 'cancelled':
        return CheckoutStatus.cancelled;
      default:
        return CheckoutStatus.open;
    }
  }

  static String _serializeStatus(CheckoutStatus status) {
    return status.toString().split('.').last;
  }
}
