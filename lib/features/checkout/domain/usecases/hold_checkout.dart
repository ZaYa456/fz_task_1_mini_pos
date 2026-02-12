import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class HoldCheckout {
  final ICheckoutRepository repository;

  HoldCheckout(this.repository);

  /// Hold (pause) the current checkout
  /// Returns a new empty checkout to replace it
  Future<Checkout> execute({
    required Checkout checkoutToHold,
  }) async {
    if (checkoutToHold.isEmpty) {
      throw Exception("Cannot hold an empty checkout.");
    }

    // Mark as held
    final heldCheckout = checkoutToHold.copyWith(
      status: CheckoutStatus.held,
    );

    await repository.saveCheckout(heldCheckout);

    // Create new active checkout
    return await repository.getOrCreateActiveCheckout();
  }
}
