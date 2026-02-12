// lib/features/checkout/domain/repositories/checkout_repository.dart
import '../entities/checkout.dart';

abstract class ICheckoutRepository {
  // Persistence only
  Future<Checkout> getOrCreateActiveCheckout();
  Future<List<Checkout>> getHeldCheckouts();
  Future<void> saveCheckout(Checkout checkout);
  Future<void> deleteCheckout(int id);
}
