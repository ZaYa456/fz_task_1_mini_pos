import 'package:hive/hive.dart';
import 'checkout_items_model.dart'; // Import the item model below

part 'checkout_model.g.dart';

@HiveType(typeId: 2)
class Checkout extends HiveObject {
  @HiveField(0)
  late int id; // You can use DateTime.now().millisecondsSinceEpoch for unique IDs

  @HiveField(1)
  late double totalAmount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late List<CheckoutItem> items; // Embed items directly in the checkout for NoSQL
}