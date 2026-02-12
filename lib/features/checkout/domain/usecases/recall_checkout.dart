import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class RecallCheckout {
  final ICheckoutRepository repository;

  RecallCheckout(this.repository);

  /// Recall a held checkout, optionally holding the current one
  Future<Checkout> execute({
    required Checkout heldCheckout,
    Checkout? currentCheckout,
  }) async {
    // 1. Handle current checkout
    if (currentCheckout != null) {
      if (currentCheckout.isEmpty) {
        // Delete empty checkout
        await repository.deleteCheckout(currentCheckout.id);
      } else {
        // Hold it
        final held = currentCheckout.copyWith(status: CheckoutStatus.held);
        await repository.saveCheckout(held);
      }
    }

    // 2. Restore held checkout to open
    final recalledCheckout = heldCheckout.copyWith(
      status: CheckoutStatus.open,
    );

    await repository.saveCheckout(recalledCheckout);

    return recalledCheckout;
  }
}
