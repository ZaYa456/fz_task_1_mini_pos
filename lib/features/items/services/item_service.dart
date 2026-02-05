import 'package:hive/hive.dart';
import '../models/item_model.dart';
import '../../checkout/models/checkout_model.dart';

class ItemService {
  final Box<Item> _itemBox;
  final Box<Checkout> _checkoutBox;

  ItemService(this._itemBox, this._checkoutBox);

  List<Item> getAll() => _itemBox.values.toList();

  Future<void> add(Item item) => _itemBox.add(item);

  Future<void> update(Item item) => item.save();

  Future<void> delete(Item item) => item.delete();

  Stream<void> watch() => _itemBox.watch().map((_) {});

  /// Check if item is referenced in any checkout (active or held)
  /// Returns a map with details about where the item is used
  Map<String, dynamic> getItemUsage(Item item) {
    final itemKey = item.key as int;
    final allCheckouts = _checkoutBox.values.toList();

    final List<Checkout> activeCheckouts = [];
    final List<Checkout> heldCheckouts = [];
    int totalQuantity = 0;

    for (final checkout in allCheckouts) {
      final hasItem = checkout.items.any((ci) => ci.itemId == itemKey);

      if (hasItem) {
        final quantity = checkout.items
            .where((ci) => ci.itemId == itemKey)
            .fold(0, (sum, ci) => sum + ci.quantity);

        totalQuantity += quantity;

        if (checkout.status == 'open') {
          activeCheckouts.add(checkout);
        } else if (checkout.status == 'held') {
          heldCheckouts.add(checkout);
        }
      }
    }

    return {
      'isUsed': activeCheckouts.isNotEmpty || heldCheckouts.isNotEmpty,
      'activeCount': activeCheckouts.length,
      'heldCount': heldCheckouts.length,
      'totalQuantity': totalQuantity,
      'activeCheckouts': activeCheckouts,
      'heldCheckouts': heldCheckouts,
    };
  }

  /// Remove item from all checkouts (both active and held)
  Future<void> removeItemFromAllCheckouts(Item item) async {
    final itemKey = item.key as int;
    final allCheckouts = _checkoutBox.values.toList();

    for (final checkout in allCheckouts) {
      final itemsToRemove =
          checkout.items.where((ci) => ci.itemId == itemKey).toList();

      if (itemsToRemove.isNotEmpty) {
        checkout.items.removeWhere((ci) => ci.itemId == itemKey);

        // Recalculate total
        checkout.totalAmount = checkout.items.fold(
          0.0,
          (sum, item) => sum + (item.priceAtSale * item.quantity),
        );

        await checkout.save();
      }
    }
  }
}
