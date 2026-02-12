import 'package:hive/hive.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/entities/checkout_item.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../models/checkout_items_model.dart';
import '../models/checkout_model.dart';

class CheckoutRepositoryImpl implements ICheckoutRepository {
  final Box<CheckoutModel> _checkoutBox;

  // Removed _itemBox from here. 
  // Checkout repo should only care about Checkout data.
  CheckoutRepositoryImpl(this._checkoutBox);

  // ---------------------------------------------------------------------------
  // CHECKOUTS
  // ---------------------------------------------------------------------------

  @override
  Future<Checkout> getOrCreateActiveCheckout() async {
    try {
      // Optimized: cleaner syntax to find the first open checkout
      final activeModel = _checkoutBox.values.firstWhere(
        (model) => model.status == 'open',
      );
      return activeModel.toEntity();
    } catch (_) {
      // Create new one if none found
      final newCheckout = CheckoutModel()
        ..id = DateTime.now().millisecondsSinceEpoch
        ..date = DateTime.now()
        ..items = []
        ..totalAmount = 0
        ..status = 'open';

      await _checkoutBox.add(newCheckout);
      return newCheckout.toEntity();
    }
  }

  @override
  Future<List<Checkout>> getHeldCheckouts() async {
    return _checkoutBox.values
        .where((c) => c.status == 'held')
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> saveCheckout(Checkout checkout) async {
    final model = CheckoutModel.fromEntity(checkout);
    final key = _findCheckoutKeyById(checkout.id);

    if (key != null) {
      await _checkoutBox.put(key, model);
    } else {
      await _checkoutBox.add(model);
    }
  }

  @override
  Future<void> deleteCheckout(int id) async {
    final key = _findCheckoutKeyById(id);

    if (key != null) {
      await _checkoutBox.delete(key);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  dynamic _findCheckoutKeyById(int id) {
    for (final key in _checkoutBox.keys) {
      final model = _checkoutBox.get(key);
      if (model?.id == id) {
        return key;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// EXTENSIONS (MAPPERS)
// ---------------------------------------------------------------------------

extension CheckoutModelExtensions on CheckoutModel {
  Checkout toEntity() {
    return Checkout(
      id: id,
      date: date,
      items: items.map((model) => model.toEntity()).toList(),
      status: _statusFromString(status),
      taxRate: 0.0, // Configure as needed or add to Hive Model later
    );
  }

  static CheckoutStatus _statusFromString(String status) {
    return CheckoutStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => CheckoutStatus.open,
    );
  }

  static CheckoutModel fromEntity(Checkout entity) {
    return CheckoutModel()
      ..id = entity.id
      ..date = entity.date
      ..items = entity.items.map((e) => CheckoutItemModel.fromEntity(e)).toList()
      ..totalAmount = entity.totalAmount
      ..status = entity.status.name; // Uses the enum name directly (e.g., "open")
  }
}

extension CheckoutItemModelExtensions on CheckoutItemModel {
  CheckoutItem toEntity() {
    return CheckoutItem(
      itemId: itemId,
      itemName: itemName,
      priceAtSale: priceAtSale,
      quantity: quantity,
    );
  }

  static CheckoutItemModel fromEntity(CheckoutItem entity) {
    return CheckoutItemModel()
      ..itemId = entity.itemId
      ..itemName = entity.itemName
      ..priceAtSale = entity.priceAtSale
      ..quantity = entity.quantity;
  }
}