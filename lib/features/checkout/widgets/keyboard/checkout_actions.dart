import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/checkout_provider.dart';
import 'checkout_intents.dart';

Map<Type, Action<Intent>> buildCheckoutActions({
  required WidgetRef ref,
  required VoidCallback onShowPaymentDialog,
  required VoidCallback onShowHeldTransactions,
  required VoidCallback onClearCart,
}) {
  final notifier = ref.read(checkoutProvider.notifier);

  return {
    HoldIntent: CallbackAction<HoldIntent>(
      onInvoke: (_) {
        if (!ref.read(checkoutProvider).isEmpty) {
          notifier.holdTransaction();
        }
        return null;
      },
    ),
    RecallIntent: CallbackAction<RecallIntent>(
      onInvoke: (_) {
        onShowHeldTransactions();
        return null;
      },
    ),
    ClearCartIntent: CallbackAction<ClearCartIntent>(
      onInvoke: (_) {
        if (!ref.read(checkoutProvider).isEmpty) {
          onClearCart();
        }
        return null;
      },
    ),
    PayIntent: CallbackAction<PayIntent>(
      onInvoke: (_) {
        final state = ref.read(checkoutProvider);
        if (!state.isEmpty && !state.isProcessing) {
          onShowPaymentDialog();
        }
        return null;
      },
    ),
    DeleteItemIntent: CallbackAction<DeleteItemIntent>(
      onInvoke: (_) {
        notifier.removeSelectedItem();
        return null;
      },
    ),
    NavigateUpIntent: CallbackAction<NavigateUpIntent>(
      onInvoke: (_) {
        notifier.selectPrevious();
        return null;
      },
    ),
    NavigateDownIntent: CallbackAction<NavigateDownIntent>(
      onInvoke: (_) {
        notifier.selectNext();
        return null;
      },
    ),
    IncrementQtyIntent: CallbackAction<IncrementQtyIntent>(
      onInvoke: (_) {
        notifier.incrementSelectedQuantity();
        return null;
      },
    ),
    DecrementQtyIntent: CallbackAction<DecrementQtyIntent>(
      onInvoke: (_) {
        notifier.decrementSelectedQuantity();
        return null;
      },
    ),
  };
}
