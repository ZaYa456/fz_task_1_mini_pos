import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class RemoveItemFromCart {
  final ICheckoutRepository repository;

  RemoveItemFromCart(this.repository);

  /// Remove one unit of an item from the cart
  /// If quantity becomes 0, removes the entire checkout item
  Future<Checkout> execute({
    required Checkout checkout,
    required int itemId,
  }) async {
    // Instead of List<CheckoutItem>.from...
    final items = [...checkout.items]; // Modern spread operator for cloning
    final existingIndex = items.indexWhere((e) => e.itemId == itemId);

    if (existingIndex == -1) {
      throw Exception("Item not found in cart.");
    }

    final currentItem = items[existingIndex];

    // Business Rule: Decrement quantity or remove entirely
    if (currentItem.quantity > 1) {
      items[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    } else {
      items.removeAt(existingIndex);
    }

    final updatedCheckout = checkout.copyWith(items: items);

    // Persist the change
    await repository.saveCheckout(updatedCheckout);

    return updatedCheckout;
  }
}
