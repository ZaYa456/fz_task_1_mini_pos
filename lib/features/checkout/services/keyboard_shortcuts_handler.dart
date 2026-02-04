import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/checkout_provider.dart';

class KeyboardShortcutsHandler {
  final WidgetRef ref;
  final VoidCallback onShowPaymentDialog;
  final VoidCallback onShowHeldTransactions;
  final VoidCallback onClearCart;

  KeyboardShortcutsHandler({
    required this.ref,
    required this.onShowPaymentDialog,
    required this.onShowHeldTransactions,
    required this.onClearCart,
  });

  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final cartState = ref.read(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    // F1 - Hold transaction
    if (event.logicalKey == LogicalKeyboardKey.f1) {
      if (!cartState.isEmpty) {
        checkoutNotifier.holdTransaction();
      }
    }
    // F2 - Recall held transaction
    else if (event.logicalKey == LogicalKeyboardKey.f2) {
      onShowHeldTransactions();
    }
    // F9 - Clear cart
    else if (event.logicalKey == LogicalKeyboardKey.f9) {
      if (!cartState.isEmpty) {
        onClearCart();
      }
    }
    // F12 - Complete checkout (if cart not empty)
    else if (event.logicalKey == LogicalKeyboardKey.f12) {
      if (!cartState.isEmpty && !cartState.isProcessing) {
        onShowPaymentDialog();
      }
    }
    // Delete - Remove selected item
    else if (event.logicalKey == LogicalKeyboardKey.delete) {
      checkoutNotifier.removeSelectedItem();
    }
    // Arrow Up - Navigate cart up
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      checkoutNotifier.selectPrevious();
    }
    // Arrow Down - Navigate cart down
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      checkoutNotifier.selectNext();
    }
    // Plus/NumpadAdd - Increment quantity of selected item
    else if (event.logicalKey == LogicalKeyboardKey.add ||
        event.logicalKey == LogicalKeyboardKey.numpadAdd ||
        (event.logicalKey == LogicalKeyboardKey.equal &&
            event.character == '+')) {
      checkoutNotifier.incrementSelectedQuantity();
    }
    // Minus/NumpadSubtract - Decrement quantity of selected item
    else if (event.logicalKey == LogicalKeyboardKey.minus ||
        event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
      checkoutNotifier.decrementSelectedQuantity();
    }
  }
}
