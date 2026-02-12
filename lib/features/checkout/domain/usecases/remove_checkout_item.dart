import 'package:fz_task_1/features/checkout/domain/entities/checkout_item.dart';

import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class RemoveCheckoutItem {
  final ICheckoutRepository repository;

  RemoveCheckoutItem(this.repository);

  /// Remove a checkout item completely (regardless of quantity)
  Future<Checkout> execute({
    required Checkout checkout,
    required int itemId,
  }) async {
    final items = List<CheckoutItem>.from(checkout.items); //

    // Check if item exists if you want to throw an exception
    if (!items.any((e) => e.itemId == itemId)) {
      throw Exception("Item not found in cart.");
    }

    // Perform removal (returns void)
    items.removeWhere((e) => e.itemId == itemId);

    final updatedCheckout = checkout.copyWith(items: items); //

    await repository.saveCheckout(updatedCheckout); //

    return updatedCheckout;
  }
}
