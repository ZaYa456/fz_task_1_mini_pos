import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class ClearCheckout {
  final ICheckoutRepository repository;

  ClearCheckout(this.repository);

  /// Clear all items from the checkout
  Future<Checkout> execute({
    required Checkout checkout,
  }) async {
    final clearedCheckout = checkout.copyWith(items: []);

    await repository.saveCheckout(clearedCheckout);

    return clearedCheckout;
  }
}
