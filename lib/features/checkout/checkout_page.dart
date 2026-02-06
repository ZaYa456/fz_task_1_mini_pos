import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/checkout_provider.dart';
import 'providers/service_providers.dart';

import 'widgets/item_grid/item_grid_panel.dart';
import 'widgets/cart_summary/cart_summary_panel.dart';
import 'widgets/dialogs/payment_dialog.dart';
import 'widgets/dialogs/held_transactions_dialog.dart';
import 'widgets/dialogs/receipt_preview_dialog.dart';
import 'widgets/dialogs/clear_cart_dialog.dart';

import 'widgets/keyboard/checkout_actions.dart';
import 'widgets/keyboard/checkout_shortcuts.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late final FocusNode _rootFocusNode;
  late final FocusNode _searchFocusNode;
  late final FocusScopeNode _checkoutScopeNode;

  @override
  void initState() {
    super.initState();

    _checkoutScopeNode = FocusScopeNode(debugLabel: 'CheckoutScope');
    _rootFocusNode = FocusNode(debugLabel: 'CheckoutRoot');
    _searchFocusNode = FocusNode(debugLabel: 'CheckoutSearch');

    // Root focus must own keyboard events on desktop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkoutScopeNode.requestFocus(_rootFocusNode);
    });
  }

  @override
  void dispose() {
    _checkoutScopeNode.dispose();
    _rootFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heldTransactionCount = ref.watch(heldTransactionCountProvider);

    return FocusScope(
      node: _checkoutScopeNode,
      autofocus: true,
      // 1. SHORTCUTS & ACTIONS MUST BE AT THE TOP (Ancestors of Focus)
      child: Shortcuts(
        shortcuts: checkoutShortcuts,
        child: Actions(
          actions: buildCheckoutActions(
            ref: ref,
            onShowPaymentDialog: _showPaymentDialog,
            onShowHeldTransactions: _showHeldTransactionsDialog,
            onClearCart: _showClearCartDialog,
          ),
          // 2. FOCUS WIDGET IS NOW A CHILD
          child: Focus(
            focusNode: _rootFocusNode,
            autofocus: true,
            // 3. GESTURE DETECTOR TRAPS CLICKS ON EMPTY SPACE
            child: GestureDetector(
              onTap: () {
                // Ensure clicking empty background reclaims focus
                if (!_rootFocusNode.hasFocus && !_searchFocusNode.hasFocus) {
                  _rootFocusNode.requestFocus();
                }
              },
              // Important: HitTestBehavior.translucent or HitTestBehavior.opaque catches clicks on empty rows/columns
              // without it, clicks on empty space would fall through to underlying widgets and not trigger focus changes
              // This is crucial for desktop where users expect to click anywhere to focus the checkout
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Checkout'),
                  actions: [
                    if (heldTransactionCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: Badge(
                            label: Text(heldTransactionCount.toString()),
                            child: IconButton(
                              icon: const Icon(Icons.pause_circle_outline),
                              tooltip: 'Held Transactions (F2)',
                              onPressed: _showHeldTransactionsDialog,
                            ),
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: _handleMenuAction,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'hold',
                          child: Row(
                            children: [
                              Icon(Icons.pause),
                              SizedBox(width: 8),
                              Text('Hold (F1)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'recall',
                          child: Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text('Recall (F2)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Clear Cart (F9)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    Expanded(
                      child: ItemGridPanel(
                        searchFocusNode: _searchFocusNode,
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[300]),
                    SizedBox(
                      width: 450,
                      child: CartSummaryPanel(
                        onHold: _holdTransaction,
                        onPay: _showPaymentDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Menu Actions ----------------

  void _handleMenuAction(String action) {
    switch (action) {
      case 'hold':
        _holdTransaction();
        break;
      case 'recall':
        _showHeldTransactionsDialog();
        break;
      case 'clear':
        _showClearCartDialog();
        break;
    }
  }

  // ---------------- Transaction Management ----------------

  void _holdTransaction() {
    final cartState = ref.read(checkoutProvider);
    if (cartState.isEmpty) return;

    ref.read(checkoutProvider.notifier).holdTransaction();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction held'),
        duration: Duration(seconds: 1),
      ),
    );

    _rootFocusNode.requestFocus();
  }

  void _showHeldTransactionsDialog() {
    final cartState = ref.read(checkoutProvider);

    if (cartState.heldCheckouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No held transactions')),
      );
      return;
    }

    HeldTransactionsDialog.show(
      context,
      heldCheckouts: cartState.heldCheckouts,
      onRecall: (index) {
        ref.read(checkoutProvider.notifier).recallTransaction(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction recalled'),
            duration: Duration(seconds: 1),
          ),
        );
        _rootFocusNode.requestFocus();
      },
      onDelete: (index) {
        ref.read(checkoutProvider.notifier).deleteHeldTransaction(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Future<void> _showClearCartDialog() async {
    final cartState = ref.read(checkoutProvider);
    if (cartState.isEmpty) return;

    final confirmed = await ClearCartDialog.show(context);
    if (confirmed && mounted) {
      ref.read(checkoutProvider.notifier).clearCart();
      _rootFocusNode.requestFocus();
    }
  }

  // ---------------- Payment ----------------

  Future<void> _showPaymentDialog() async {
    final cartState = ref.read(checkoutProvider);
    if (cartState.isEmpty || cartState.isProcessing) return;

    final paymentInfo = await PaymentDialog.show(
      context,
      cartState.total,
    );

    if (paymentInfo != null && mounted) {
      await _processPayment(paymentInfo);
    } else {
      _rootFocusNode.requestFocus();
    }
  }

  Future<void> _processPayment(paymentInfo) async {
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final receiptService = ref.read(receiptServiceProvider);
    final completedCheckout = ref.read(checkoutProvider).activeCheckout;

    try {
      await checkoutNotifier.completeCheckout(paymentInfo);

      if (mounted) {
        await ReceiptPreviewDialog.showPaymentSuccess(
          context,
          checkout: completedCheckout,
          paymentInfo: paymentInfo,
          receiptService: receiptService,
        );

        _rootFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during checkout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _rootFocusNode.requestFocus();
      }
    }
  }
}
