import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class GetHeldCheckouts {
  final ICheckoutRepository repository;

  GetHeldCheckouts(this.repository);

  /// Get all held (paused) checkouts
  Future<List<Checkout>> execute() async {
    return await repository.getHeldCheckouts();
  }
}
