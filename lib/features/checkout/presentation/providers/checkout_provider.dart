import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/items/domain/entities/item.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/entities/checkout_item.dart';
import '../state/cart_state.dart';
import '../../../payments/domain/entities/payment_info.dart';

/// Checkout state notifier - Refactored to use Use Cases
class CheckoutNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(CartState.initial()) {
    loadInitialState();
  }

  /// Load initial checkout state
  Future<void> loadInitialState() async {
    try {
      final getActiveCheckout = _ref.read(getActiveCheckoutProvider);
      final getHeldCheckouts = _ref.read(getHeldCheckoutsProvider);

      final activeCheckout = await getActiveCheckout.execute();
      final heldCheckouts = await getHeldCheckouts.execute();

      state = CartState(
        activeCheckout: activeCheckout,
        heldCheckouts: heldCheckouts,
      );
    } catch (e) {
      // Handle initialization error
      state = CartState.initial();
      // print a message
      print('Error loading initial checkout state: ${e.toString()}');
    }
  }

  // ==========================================================================
  // QUANTITY INPUT MANAGEMENT
  // ==========================================================================

  /// Handle number key presses (e.g. typing "3" then "0" becomes 30)
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

  /// Reset pending quantity to 1 (e.g. on Escape key)
  void resetPendingQuantity() {
    state = state.copyWith(pendingQuantity: 1, isDefaultQuantity: true);
  }

  /// Backspace handler for pending quantity
  void backspacePendingQuantity() {
    final current = state.pendingQuantity;

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

  // ==========================================================================
  // CART OPERATIONS
  // ==========================================================================

  /// Add item to cart
  Future<bool> addItem(Item item, {int? quantity}) async {
    try {
      // 1. Determine effective quantity
      int effectiveQty = quantity ?? state.pendingQuantity;

      if (effectiveQty <= 0) effectiveQty = 1;

      // 2. Execute use case
      final addItemToCart = _ref.read(addItemToCartProvider);

      final updatedCheckout = await addItemToCart.execute(
        checkout: state.activeCheckout,
        itemId: item.id,
        itemName: item.name,
        price: item.price,
        quantity: effectiveQty,
        isStockManaged: item.isStockManaged,
      );

      // 3. Find selected index for the added item
      final itemIndex = updatedCheckout.items.indexWhere(
        (e) => e.itemId == item.id,
      );

      // 4. Update state and reset pending quantity
      state = CartState(
        activeCheckout: updatedCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: itemIndex,
        pendingQuantity: 1,
        isDefaultQuantity: true,
      );

      return true;
    } catch (e) {
      // Stock validation or other errors
      print('Error adding item to cart: ${e.toString()}');
      return false;
    }
  }

  /// Remove one unit of item from cart
  Future<void> removeItem(Item item) async {
    try {
      final removeItemFromCart = _ref.read(removeItemFromCartProvider);

      final updatedCheckout = await removeItemFromCart.execute(
        checkout: state.activeCheckout,
        itemId: item.id,
      );

      state = CartState(
        activeCheckout: updatedCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: state.selectedItemIndex,
      );
    } catch (e) {
      // Handle error (item not found, etc.)
      print('Error removing item from cart: ${e.toString()}');
    }
  }

  /// Set quantity for a checkout item
  Future<bool> setItemQuantity(
      CheckoutItem checkoutItem, int newQuantity) async {
    try {
      final setItemQuantity = _ref.read(setItemQuantityProvider);

      final updatedCheckout = await setItemQuantity.execute(
        checkout: state.activeCheckout,
        itemId: checkoutItem.itemId,
        newQuantity: newQuantity,
      );

      // Update selected index if item was removed
      int? newSelectedIndex = state.selectedItemIndex;
      if (newQuantity <= 0 &&
          state.selectedItemIndex != null &&
          state.selectedItemIndex! >= updatedCheckout.items.length) {
        newSelectedIndex = updatedCheckout.items.isEmpty
            ? null
            : updatedCheckout.items.length - 1;
      }

      state = CartState(
        activeCheckout: updatedCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: newSelectedIndex,
      );

      return true;
    } catch (e) {
      print('Error setting item quantity: ${e.toString()}');
      return false;
    }
  }

  /// Remove checkout item completely
  Future<void> removeCheckoutItem(CheckoutItem checkoutItem) async {
    try {
      final itemIndex = state.activeCheckout.items.indexOf(checkoutItem);

      final removeCheckoutItem = _ref.read(removeCheckoutItemProvider);

      final updatedCheckout = await removeCheckoutItem.execute(
        checkout: state.activeCheckout,
        itemId: checkoutItem.itemId,
      );

      // Update selected index
      int? newSelectedIndex = state.selectedItemIndex;
      if (state.selectedItemIndex == itemIndex) {
        newSelectedIndex = null;
      } else if (state.selectedItemIndex != null &&
          state.selectedItemIndex! > itemIndex) {
        newSelectedIndex = state.selectedItemIndex! - 1;
      }

      state = CartState(
        activeCheckout: updatedCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: newSelectedIndex,
      );
    } catch (e) {
      // Handle error
      print('Error removing checkout item: ${e.toString()}');
    }
  }

  /// Get item quantity in cart
  int getItemQuantity(Item item) {
    final entry = state.activeCheckout.items.cast<CheckoutItem?>().firstWhere(
          (e) => e?.itemId == item.id,
          orElse: () => null,
        );
    return entry?.quantity ?? 0;
  }

  // ==========================================================================
  // SELECTION MANAGEMENT
  // ==========================================================================

  /// Select cart item by index
  void selectItem(int? index) {
    state = state.copyWith(selectedItemIndex: index);
  }

  /// Navigate selection up
  void selectPrevious() {
    if (state.selectedItemIndex == null || state.selectedItemIndex == 0) {
      return;
    }
    state = state.copyWith(selectedItemIndex: state.selectedItemIndex! - 1);
  }

  /// Navigate selection down
  void selectNext() {
    if (state.selectedItemIndex == null ||
        state.selectedItemIndex! >= state.activeCheckout.items.length - 1) {
      return;
    }
    state = state.copyWith(selectedItemIndex: state.selectedItemIndex! + 1);
  }

  /// Increment quantity of selected item
  Future<void> incrementSelectedQuantity() async {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    await setItemQuantity(item, item.quantity + 1);
  }

  /// Decrement quantity of selected item
  Future<void> decrementSelectedQuantity() async {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    await setItemQuantity(item, item.quantity - 1);
  }

  /// Remove selected item
  Future<void> removeSelectedItem() async {
    if (state.selectedItemIndex == null) return;

    final item = state.activeCheckout.items[state.selectedItemIndex!];
    await removeCheckoutItem(item);
  }

  // ==========================================================================
  // TRANSACTION MANAGEMENT
  // ==========================================================================

  /// Hold current transaction
  Future<void> holdTransaction() async {
    if (state.isEmpty) return;

    try {
      final holdCheckout = _ref.read(holdCheckoutProvider);

      // Execute the hold
      final heldModel = await holdCheckout.execute(
        checkoutToHold: state.activeCheckout,
      );

      // Update held checkouts: add the held checkout (with updated status)
      final updatedHeldCheckouts = [...state.heldCheckouts, heldModel];

      // Create a fresh new active checkout directly (not via getOrCreateActiveCheckout to avoid auto-recall)
      final newActiveCheckout = Checkout(
        id: DateTime.now().millisecondsSinceEpoch,
        date: DateTime.now(),
        items: [],
      );

      state = CartState(
        activeCheckout: newActiveCheckout,
        heldCheckouts: updatedHeldCheckouts,
        selectedItemIndex: null, // Reset selection
        pendingQuantity: 1, // Reset quantity input
        isDefaultQuantity: true, // Reset to default
      );
    } catch (e) {
      // Optional: log error
      print('Error holding transaction: ${e.toString()}');
      rethrow;
    }
  }

  /// Recall a held transaction
  Future<void> recallTransaction(int index) async {
    if (index < 0 || index >= state.heldCheckouts.length) return;

    try {
      final heldCheckout = state.heldCheckouts[index];

      // Recall the held checkout
      final recalledCheckout = await _ref.read(recallCheckoutProvider).execute(
            heldCheckout: heldCheckout,
            currentCheckout: state.activeCheckout,
          );

      // Remove recalled checkout from held checkouts
      final updatedHeldCheckouts = List<Checkout>.from(state.heldCheckouts)
        ..removeAt(index);

      // Set the recalled checkout as active
      state = CartState(
        activeCheckout: recalledCheckout,
        heldCheckouts: updatedHeldCheckouts,
        selectedItemIndex: null, // Reset selection after recalling
        transactionJustRecalled: true, // Signal that a recall happened
      );
    } catch (e) {
      print('Error recalling transaction: ${e.toString()}');
      rethrow;
    }
  }

  /// Delete a held transaction
  Future<void> deleteHeldTransaction(int index) async {
    if (index < 0 || index >= state.heldCheckouts.length) return;

    try {
      final checkout = state.heldCheckouts[index];

      final deleteHeldCheckout = _ref.read(deleteHeldCheckoutProvider);

      await deleteHeldCheckout.execute(checkout: checkout);

      final updatedHeldCheckouts = List<Checkout>.from(state.heldCheckouts)
        ..removeAt(index);

      state = CartState(
        activeCheckout: state.activeCheckout,
        heldCheckouts: updatedHeldCheckouts,
        selectedItemIndex: state.selectedItemIndex,
      );
    } catch (e) {
      // Handle error
      print('Error deleting held transaction: ${e.toString()}');
      rethrow;
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      final clearCheckout = _ref.read(clearCheckoutProvider);

      final clearedCheckout = await clearCheckout.execute(
        checkout: state.activeCheckout,
      );

      state = CartState(
        activeCheckout: clearedCheckout,
        heldCheckouts: state.heldCheckouts,
        selectedItemIndex: null,
      );
    } catch (e) {
      // Handle error
      print('Error clearing cart: ${e.toString()}');
    }
  }

  /// Complete checkout
  Future<void> completeCheckout(PaymentInfo paymentInfo) async {
    state = state.copyWith(isProcessing: true);

    try {
      final completeCheckout = _ref.read(completeCheckoutProvider);

      await completeCheckout.execute(
        checkout: state.activeCheckout,
        payment: paymentInfo,
      );

      // Create new active checkout
      final getActiveCheckout = _ref.read(getActiveCheckoutProvider);
      final newActiveCheckout = await getActiveCheckout.execute();

      state = CartState(
        activeCheckout: newActiveCheckout,
        heldCheckouts: state.heldCheckouts,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }

  /// Reload held transactions
  Future<void> reloadHeldTransactions() async {
    try {
      final getHeldCheckouts = _ref.read(getHeldCheckoutsProvider);
      final heldCheckouts = await getHeldCheckouts.execute();

      state = state.copyWith(heldCheckouts: heldCheckouts);
    } catch (e) {
      // Handle error
      print('Error reloading held transactions: ${e.toString()}');
      rethrow;
    }
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CartState>((ref) {
  return CheckoutNotifier(ref);
});

// =============================================================================
// CONVENIENT COMPUTED PROVIDERS
// =============================================================================

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
