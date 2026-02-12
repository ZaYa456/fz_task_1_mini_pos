import 'package:fz_task_1/features/items/domain/repositories/item_repository.dart'; // Add this
import 'package:fz_task_1/features/payments/domain/entities/payment_info.dart';

import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class CompleteCheckout {
  final ICheckoutRepository repository;
  final ItemRepository itemRepository; // Add this

  CompleteCheckout(this.repository, this.itemRepository);

  Future<void> execute({
    required Checkout checkout,
    required PaymentInfo payment,
  }) async {
    if (!payment.isValid) throw Exception("Invalid payment amount.");
    if (checkout.items.isEmpty)
      throw Exception("Cannot complete an empty checkout.");

    // 1. Final Stock Validation via ItemRepository
    for (final cartItem in checkout.items) {
      final storeItem = await itemRepository.getById(cartItem.itemId);

      if (storeItem == null) {
        throw Exception("Item '${cartItem.itemName}' no longer exists.");
      }

      if (storeItem.isStockManaged &&
          storeItem.stockQuantity < cartItem.quantity) {
        throw Exception("Insufficient stock for '${cartItem.itemName}'.");
      }
    }

    // 2. Deduct Stock via ItemRepository
    for (final cartItem in checkout.items) {
      final storeItem = (await itemRepository.getById(cartItem.itemId))!;
      if (storeItem.isStockManaged) {
        final newStock = storeItem.stockQuantity - cartItem.quantity;
        await itemRepository.updateStock(cartItem.itemId, newStock);
      }
    }

    // 3. Mark as Completed
    final completedCheckout = checkout.copyWith(
      status: CheckoutStatus.completed,
      date: DateTime.now(),
    );

    await repository.saveCheckout(completedCheckout);
  }
}
