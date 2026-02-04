import 'package:hive/hive.dart';
import '../models/checkout_model.dart';
import '../models/checkout_items_model.dart';
import '../../items/models/item_model.dart';
import '../models/payment_info.dart';

class CheckoutService {
  final Box<Item> _itemBox;
  final Box<Checkout> _checkoutBox;

  CheckoutService(this._itemBox, this._checkoutBox);

  /// Add an item to the checkout
  /// Returns true if successful, false if stock limit reached
  bool addItemToCheckout({
    required Checkout checkout,
    required Item item,
    int quantity = 1,
  }) {
    final items = checkout.items;
    final existingIndex = items.indexWhere((e) => e.itemId == item.key);

    // Check stock availability
    if (item.isStockManaged) {
      final currentQty =
          existingIndex != -1 ? items[existingIndex].quantity : 0;

      if (currentQty + quantity > item.stockQuantity) {
        return false; // Stock limit reached
      }
    }

    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(
        CheckoutItem()
          ..itemId = item.key as int
          ..itemName = item.name
          ..priceAtSale = item.price
          ..quantity = quantity,
      );
    }

    _recalculateTotal(checkout);
    return true;
  }

  /// Remove one unit of an item from checkout
  void removeItemFromCheckout({
    required Checkout checkout,
    required Item item,
  }) {
    final items = checkout.items;
    final existingIndex = items.indexWhere((e) => e.itemId == item.key);

    if (existingIndex == -1) return;

    if (items[existingIndex].quantity > 1) {
      items[existingIndex].quantity -= 1;
    } else {
      items.removeAt(existingIndex);
    }

    _recalculateTotal(checkout);
  }

  /// Set quantity for a checkout item
  /// Returns true if successful, false if stock limit would be exceeded
  bool setItemQuantity({
    required Checkout checkout,
    required CheckoutItem checkoutItem,
    required int newQuantity,
  }) {
    final item = _itemBox.get(checkoutItem.itemId);

    if (item == null) return false;

    // Check stock if managed
    if (item.isStockManaged && newQuantity > item.stockQuantity) {
      return false;
    }

    if (newQuantity <= 0) {
      checkout.items.remove(checkoutItem);
    } else {
      checkoutItem.quantity = newQuantity;
    }

    _recalculateTotal(checkout);
    return true;
  }

  /// Remove a specific checkout item completely
  void removeCheckoutItem({
    required Checkout checkout,
    required CheckoutItem checkoutItem,
  }) {
    checkout.items.remove(checkoutItem);
    _recalculateTotal(checkout);
  }

  /// Get current quantity of an item in the checkout
  int getItemQuantityInCheckout({
    required Checkout checkout,
    required Item item,
  }) {
    final entry = checkout.items.cast<CheckoutItem?>().firstWhere(
          (e) => e?.itemId == item.key,
          orElse: () => null,
        );
    return entry?.quantity ?? 0;
  }

  /// Complete the checkout transaction
  Future<void> completeCheckout({
    required Checkout checkout,
    required PaymentInfo paymentInfo,
  }) async {
    if (!paymentInfo.isValid) {
      throw Exception('Invalid payment: insufficient amount');
    }

    // Update stock for each item
    for (final entry in checkout.items) {
      final item = _itemBox.get(entry.itemId);
      if (item != null && item.isStockManaged) {
        if (item.stockQuantity < entry.quantity) {
          throw Exception(
            'Insufficient stock for ${item.name}. Available: ${item.stockQuantity}, Required: ${entry.quantity}',
          );
        }
        item.stockQuantity -= entry.quantity;
        await item.save();
      }
    }

    // Mark checkout as completed
    checkout
      ..status = 'completed'
      ..date = DateTime.now()
      ..totalAmount = paymentInfo.totalDue;

    await checkout.save();
  }

  /// Recalculate and save checkout total
  void _recalculateTotal(Checkout checkout) {
    checkout.totalAmount = checkout.items.fold(
      0,
      (sum, item) => sum + (item.priceAtSale * item.quantity),
    );
    checkout.save();
  }

  /// Calculate subtotal
  double calculateSubtotal(Checkout checkout) {
    return checkout.items.fold(
      0,
      (sum, item) => sum + (item.priceAtSale * item.quantity),
    );
  }

  /// Calculate tax (configure rate as needed)
  double calculateTax(Checkout checkout, {double taxRate = 0.0}) {
    return calculateSubtotal(checkout) * taxRate;
  }

  /// Calculate grand total
  double calculateGrandTotal(Checkout checkout, {double taxRate = 0.0}) {
    return calculateSubtotal(checkout) +
        calculateTax(checkout, taxRate: taxRate);
  }

  /// Auto-fix stock issues by adjusting quantities or removing items
  /// Returns a new Checkout instance with fixed items
  Checkout autoFixStockIssues(Checkout checkout) {
    final itemsToKeep = <CheckoutItem>[];

    for (final checkoutItem in checkout.items) {
      final item = _itemBox.get(checkoutItem.itemId);

      // Item deleted - skip (remove from cart)
      if (item == null) {
        continue;
      }

      // Not stock managed - keep as is
      if (!item.isStockManaged) {
        itemsToKeep.add(checkoutItem);
        continue;
      }

      // Out of stock - skip (remove from cart)
      if (item.stockQuantity <= 0) {
        continue;
      }

      // Insufficient stock - adjust quantity
      if (checkoutItem.quantity > item.stockQuantity) {
        // Create new CheckoutItem with adjusted quantity
        final adjustedItem = CheckoutItem()
          ..itemId = checkoutItem.itemId
          ..itemName = checkoutItem.itemName
          ..priceAtSale = checkoutItem.priceAtSale
          ..quantity = item.stockQuantity;
        itemsToKeep.add(adjustedItem);
      } else {
        // Stock is sufficient - keep as is
        itemsToKeep.add(checkoutItem);
      }
    }

    // Update checkout with fixed items
    checkout.items.clear();
    checkout.items.addAll(itemsToKeep);

    _recalculateTotal(checkout);

    return checkout;
  }
}
