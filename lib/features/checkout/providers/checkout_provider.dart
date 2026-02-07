import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/checkout/services/checkout_service.dart';
import 'package:fz_task_1/features/checkout/services/transaction_manager.dart';

import '../models/checkout_model.dart';
import '../models/checkout_items_model.dart';
import '../../items/models/item_model.dart';
import '../models/cart_state.dart';
import '../models/payment_info.dart';
import 'service_providers.dart';

/// Checkout state notifier
class CheckoutNotifier extends StateNotifier<CartState> {
  final CheckoutService _checkoutService;
  final TransactionManager _transactionManager;

  CheckoutNotifier(this._checkoutService, this._transactionManager)
      : super(CartState(
          activeCheckout: _transactionManager.loadOrCreateActiveCheckout(),
          heldCheckouts: _transactionManager.loadHeldCheckouts(),
        ));

  /// NEW: Handle number key presses (e.g. typing "3" then "0" becomes 30)
  void appendPendingQuantity(int digit) {
    if (digit < 0 || digit > 9) return;

    int newQty;

    if (state.isDefaultQuantity) {
      // First digit typed - replace the default
      newQty = digit;
    } else {
      // Subsequent digits - append
      newQty = (state.pendingQuantity * 10) + digit;
    }
    // Safety cap (optional, e.g. max 999)
    if (newQty > 999) newQty = 999;
    if (newQty == 0) newQty = 1; // Prevent 0 quantity

    state = state.copyWith(pendingQuantity: newQty, isDefaultQuantity: false);
  }

  /// NEW: Reset pending quantity to 1 (e.g. on Escape key)
  void resetPendingQuantity() {
    state = state.copyWith(pendingQuantity: 1, isDefaultQuantity: true);
  }

  void backspacePendingQuantity() {
    final current = state.pendingQuantity;

    // Nothing to delete
    if (current <= 1) {
      state = state.copyWith(pendingQuantity: 1, isDefaultQuantity: true);
      return;
    }

    final asString = current.toString();

    if (asString.length <= 1) {
      state = state.copyWith(pendingQuantity: 1, isDefaultQuantity: true);
      return;
    }

    final newQty = int.parse(asString.substring(0, asString.length - 1));

    state = state.copyWith(
      pendingQuantity: newQty > 0 ? newQty : 1,
    );
  }

  /// Add item to cart
  /// If quantity is NOT passed explicitly, use state.pendingQuantity
  bool addItem(Item item, {int? quantity}) {
    // 1. Determine effective quantity
    // If 'quantity' is passed (from a dialog?), use it.
    // If 'quantity' is null (from a tap?), use the pendingQuantity.
    // We use '??' (OR) instead of '+' (PLUS).
    int effectiveQty = quantity ?? state.pendingQuantity;

    /// Safety: If for some reason pending is 0, force it to 1.
    /// This is to ensure we never add 0 or negative
    /// unless explicitly handling returns (which is advanced)
    if (effectiveQty <= 0) effectiveQty = 1;

    final success = _checkoutService.addItemToCheckout(
      checkout: state.activeCheckout,
      item: item,
      quantity: effectiveQty,
    );

    if (success) {
      final itemIndex = state.activeCheckout.items.indexWhere(
        (e) => e.itemId == item.key,
      );

      // 2. Force new reference AND RESET pendingQuantity back to 1 immediately
      // This is crucial. If we don't reset, the NEXT item will also use this quantity.
      state = CartState(
        activeCheckout: state.activeCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: itemIndex,
        isProcessing: state.isProcessing,
        pendingQuantity: 1, // <--- IMPORTANT: Reset to 1 after adding
        isDefaultQuantity: true, // Reset to default state
      );
    }

    return success;
  }

  /// Remove one unit of item from cart
  void removeItem(Item item) {
    _checkoutService.removeItemFromCheckout(
      checkout: state.activeCheckout,
      item: item,
    );

    // Force new reference
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: state.selectedItemIndex,
      isProcessing: state.isProcessing,
    );
  }

  /// Set quantity for a checkout item
  bool setItemQuantity(CheckoutItem checkoutItem, int newQuantity) {
    final success = _checkoutService.setItemQuantity(
      checkout: state.activeCheckout,
      checkoutItem: checkoutItem,
      newQuantity: newQuantity,
    );

    if (success) {
      // Update selected index if item was removed
      int? newSelectedIndex = state.selectedItemIndex;
      if (newQuantity <= 0 &&
          state.selectedItemIndex != null &&
          state.selectedItemIndex! >= state.activeCheckout.items.length) {
        newSelectedIndex = state.activeCheckout.items.isEmpty
            ? null
            : state.activeCheckout.items.length - 1;
      }

      // Force new reference
      state = CartState(
        activeCheckout: state.activeCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: newSelectedIndex,
        isProcessing: state.isProcessing,
      );
    }

    return success;
  }

  /// Remove checkout item completely
  void removeCheckoutItem(CheckoutItem checkoutItem) {
    final itemIndex = state.activeCheckout.items.indexOf(checkoutItem);

    _checkoutService.removeCheckoutItem(
      checkout: state.activeCheckout,
      checkoutItem: checkoutItem,
    );

    // Update selected index
    int? newSelectedIndex = state.selectedItemIndex;
    if (state.selectedItemIndex == itemIndex) {
      newSelectedIndex = null;
    } else if (state.selectedItemIndex != null &&
        state.selectedItemIndex! > itemIndex) {
      newSelectedIndex = state.selectedItemIndex! - 1;
    }

    // Force new reference
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: newSelectedIndex,
      isProcessing: state.isProcessing,
    );
  }

  /// Get item quantity in cart
  int getItemQuantity(Item item) {
    return _checkoutService.getItemQuantityInCheckout(
      checkout: state.activeCheckout,
      item: item,
    );
  }

  /// Select cart item by index
  void selectItem(int? index) {
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: index,
      isProcessing: state.isProcessing,
    );
  }

  /// Navigate selection up
  void selectPrevious() {
    if (state.selectedItemIndex == null || state.selectedItemIndex == 0) {
      return;
    }

    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: state.selectedItemIndex! - 1,
      isProcessing: state.isProcessing,
    );
  }

  /// Navigate selection down
  void selectNext() {
    if (state.selectedItemIndex == null ||
        state.selectedItemIndex! >= state.activeCheckout.items.length - 1) {
      return;
    }

    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: state.selectedItemIndex! + 1,
      isProcessing: state.isProcessing,
    );
  }

  /// Increment quantity of selected item
  void incrementSelectedQuantity() {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    setItemQuantity(item, item.quantity + 1);
  }

  /// Decrement quantity of selected item
  void decrementSelectedQuantity() {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    setItemQuantity(item, item.quantity - 1);
  }

  /// Remove selected item
  void removeSelectedItem() {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    removeCheckoutItem(item);
  }

  /// Hold current transaction
  void holdTransaction() {
    if (state.isEmpty) return;

    _transactionManager.holdCheckout(state.activeCheckout);

    final newActiveCheckout = _transactionManager.createNewCheckout();
    final updatedHeldCheckouts = [
      ...state.heldCheckouts,
      state.activeCheckout,
    ];

    state = CartState(
      activeCheckout: newActiveCheckout,
      heldCheckouts: updatedHeldCheckouts,
    );
  }

  /// Recall a held transaction
  void recallTransaction(int index) {
    if (index < 0 || index >= state.heldCheckouts.length) return;

    final heldCheckout = state.heldCheckouts[index];

    _transactionManager.recallCheckout(
      heldCheckout: heldCheckout,
      currentCheckout: state.isEmpty ? null : state.activeCheckout,
    );

    final updatedHeldCheckouts = List<Checkout>.from(state.heldCheckouts)
      ..removeAt(index);

    // Add current to held if not empty
    if (!state.isEmpty) {
      updatedHeldCheckouts.add(state.activeCheckout);
    }

    state = CartState(
      activeCheckout: heldCheckout,
      heldCheckouts: updatedHeldCheckouts,
    );
  }

  /// Delete a held transaction
  void deleteHeldTransaction(int index) {
    if (index < 0 || index >= state.heldCheckouts.length) return;

    final checkout = state.heldCheckouts[index];
    _transactionManager.deleteHeldCheckout(checkout);

    final updatedHeldCheckouts = List<Checkout>.from(state.heldCheckouts)
      ..removeAt(index);

    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: updatedHeldCheckouts,
      selectedItemIndex: state.selectedItemIndex,
      isProcessing: state.isProcessing,
    );
  }

  /// Clear cart
  void clearCart() {
    _transactionManager.clearCheckout(state.activeCheckout);

    // Force new reference
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: null,
      isProcessing: state.isProcessing,
    );
  }

  /// Complete checkout
  Future<void> completeCheckout(PaymentInfo paymentInfo) async {
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: state.heldCheckouts,
      selectedItemIndex: state.selectedItemIndex,
      isProcessing: true,
    );

    try {
      await _checkoutService.completeCheckout(
        checkout: state.activeCheckout,
        paymentInfo: paymentInfo,
      );

      // Create new active checkout
      final newActiveCheckout = _transactionManager.createNewCheckout();

      state = CartState(
        activeCheckout: newActiveCheckout,
        heldCheckouts: state.heldCheckouts,
      );
    } catch (e) {
      state = CartState(
        activeCheckout: state.activeCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: state.selectedItemIndex,
        isProcessing: false,
      );
      rethrow;
    }
  }

  /// Reload held transactions
  void reloadHeldTransactions() {
    state = CartState(
      activeCheckout: state.activeCheckout,
      heldCheckouts: _transactionManager.loadHeldCheckouts(),
      selectedItemIndex: state.selectedItemIndex,
      isProcessing: state.isProcessing,
    );
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CartState>((ref) {
  final checkoutService = ref.watch(checkoutServiceProvider);
  final transactionManager = ref.watch(transactionManagerProvider);

  final notifier = CheckoutNotifier(
    checkoutService,
    transactionManager,
  );

  // ❌ REMOVED: Auto-fix listener - we now rely on visual warnings instead
  // Items stay in cart and show warnings until cashier manually removes them

  return notifier;
});

/// Convenient computed providers
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(checkoutProvider).itemCount;
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(checkoutProvider).subtotal;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(checkoutProvider).total;
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(checkoutProvider).isEmpty;
});

final heldTransactionCountProvider = Provider<int>((ref) {
  return ref.watch(checkoutProvider).heldCheckouts.length;
});
