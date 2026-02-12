import 'package:fz_task_1/features/items/domain/repositories/item_repository.dart'; // Add this
import '../entities/checkout.dart';
import '../entities/checkout_item.dart';
import '../repositories/checkout_repository.dart';

class SetItemQuantity {
  final ICheckoutRepository repository;
  final ItemRepository itemRepository; // Add this

  SetItemQuantity(this.repository, this.itemRepository);

  /// Set specific quantity for a checkout item
  /// Returns updated checkout or throws if stock insufficient
  Future<Checkout> execute({
    required Checkout checkout,
    required int itemId,
    required int newQuantity,
  }) async {
    final items = List<CheckoutItem>.from(checkout.items);
    final existingIndex = items.indexWhere((e) => e.itemId == itemId);

    if (existingIndex == -1) {
      throw Exception("Item not found in cart.");
    }

    final checkoutItem = items[existingIndex];

    // 1. Get item from ItemRepository to check stock
    final item = await itemRepository.getById(itemId);

    if (item == null) {
      // Item was deleted - allow reducing to 0 (removal), but not increasing
      if (newQuantity <= 0) {
        items.removeAt(existingIndex);
      } else {
        throw Exception(
          "Cannot modify deleted item. Please remove it from cart.",
        );
      }
    } else {
      // 2. Business Rule: Stock Validation (if managed and increasing)
      if (item.isStockManaged && newQuantity > checkoutItem.quantity) {
        if (newQuantity > item.stockQuantity) {
          throw Exception(
            "Insufficient stock: ${item.stockQuantity} available.",
          );
        }
      }

      // 3. Update or remove
      if (newQuantity <= 0) {
        items.removeAt(existingIndex);
      } else {
        items[existingIndex] = checkoutItem.copyWith(quantity: newQuantity);
      }
    }

    final updatedCheckout = checkout.copyWith(items: items);

    // 4. Persist to Checkout storage
    await repository.saveCheckout(updatedCheckout);

    return updatedCheckout;
  }
}
