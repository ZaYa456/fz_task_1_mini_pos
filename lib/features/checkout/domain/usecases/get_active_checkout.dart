import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class GetActiveCheckout {
  final ICheckoutRepository repository;

  GetActiveCheckout(this.repository);

  /// Get or create the active (open) checkout
  Future<Checkout> execute() async {
    return await repository.getOrCreateActiveCheckout();
  }
}
