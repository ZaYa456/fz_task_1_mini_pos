import 'package:hive/hive.dart';
import '../models/checkout_model.dart';
import '../../../services/hive_setup.dart';

class TransactionManager {
  final Box<Checkout> _checkoutBox;

  TransactionManager(this._checkoutBox);

  /// Create a new empty checkout
  Checkout createNewCheckout() {
    final checkout = Checkout()
      ..id = DateTime.now().millisecondsSinceEpoch
      ..date = DateTime.now()
      ..items = []
      ..totalAmount = 0
      ..status = 'open';

    _checkoutBox.add(checkout);
    return checkout;
  }

  /// Load or create the active checkout
  Checkout loadOrCreateActiveCheckout() {
    return _checkoutBox.values.firstWhere(
      (c) => c.status == 'open',
      orElse: createNewCheckout,
    );
  }

  /// Load all held checkouts
  List<Checkout> loadHeldCheckouts() {
    return _checkoutBox.values.where((c) => c.status == 'held').toList();
  }

  /// Hold the current checkout
  void holdCheckout(Checkout checkout) {
    checkout.status = 'held';
    checkout.save();
  }

  /// Recall a held checkout and optionally hold the current one
  Checkout recallCheckout({
    required Checkout heldCheckout,
    Checkout? currentCheckout,
  }) {
    // Save or delete current checkout
    if (currentCheckout != null) {
      if (currentCheckout.items.isEmpty) {
        currentCheckout.delete();
      } else {
        holdCheckout(currentCheckout);
      }
    }

    // Restore held checkout
    heldCheckout.status = 'open';
    heldCheckout.save();

    return heldCheckout;
  }

  /// Clear all items from a checkout
  void clearCheckout(Checkout checkout) {
    checkout.items.clear();
    checkout.totalAmount = 0;
    checkout.save();
  }

  /// Delete a held checkout
  void deleteHeldCheckout(Checkout checkout) {
    checkout.delete();
  }

  /// Update checkout total
  void updateTotal(Checkout checkout, double total) {
    checkout.totalAmount = total;
    checkout.save();
  }
}
