import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class DeleteHeldCheckout {
  final ICheckoutRepository repository;

  DeleteHeldCheckout(this.repository);

  /// Permanently delete a held checkout
  Future<void> execute({
    required Checkout checkout,
  }) async {
    if (checkout.status != CheckoutStatus.held) {
      throw Exception("Can only delete held checkouts.");
    }

    await repository.deleteCheckout(checkout.id);
  }
}
