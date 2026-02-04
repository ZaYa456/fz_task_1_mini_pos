import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/checkout_provider.dart';
import 'providers/service_providers.dart';
import 'services/keyboard_shortcuts_handler.dart';
import 'widgets/item_grid/item_grid_panel.dart';
import 'widgets/cart_summary/cart_summary_panel.dart';
import 'widgets/dialogs/payment_dialog.dart';
import 'widgets/dialogs/held_transactions_dialog.dart';
import 'widgets/dialogs/receipt_preview_dialog.dart';
import 'widgets/dialogs/clear_cart_dialog.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late final FocusNode _searchFocusNode;
  late final FocusNode _keyboardFocusNode;
  late KeyboardShortcutsHandler _shortcutsHandler;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _keyboardFocusNode = FocusNode();

    // Auto-focus search for barcode scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize shortcuts handler with current ref
    _shortcutsHandler = KeyboardShortcutsHandler(
      ref: ref,
      onShowPaymentDialog: _showPaymentDialog,
      onShowHeldTransactions: _showHeldTransactionsDialog,
      onClearCart: _showClearCartDialog,
    );

    final heldTransactionCount = ref.watch(heldTransactionCountProvider);

    return KeyboardListener(
      focusNode: _keyboardFocusNode..requestFocus(),
      onKeyEvent: _shortcutsHandler.handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Checkout"),
          actions: [
            // Held transactions indicator
            if (heldTransactionCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Badge(
                    label: Text(heldTransactionCount.toString()),
                    child: IconButton(
                      icon: const Icon(Icons.pause_circle_outline),
                      onPressed: _showHeldTransactionsDialog,
                      tooltip: "Held Transactions (F2)",
                    ),
                  ),
                ),
              ),

            // Quick actions menu
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
                      Text("Hold (F1)"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'recall',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text("Recall (F2)"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Clear Cart (F9)"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            // Item grid panel
            Expanded(
              child: ItemGridPanel(searchFocusNode: _searchFocusNode),
            ),

            // Divider
            Container(width: 1, color: Colors.grey[300]),

            // Cart summary panel
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
        content: Text("Transaction held"),
        duration: Duration(seconds: 1),
      ),
    );

    _searchFocusNode.requestFocus();
  }

  void _showHeldTransactionsDialog() {
    final cartState = ref.read(checkoutProvider);

    if (cartState.heldCheckouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No held transactions")),
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
            content: Text("Transaction recalled"),
            duration: Duration(seconds: 1),
          ),
        );
        _searchFocusNode.requestFocus();
      },
      onDelete: (index) {
        ref.read(checkoutProvider.notifier).deleteHeldTransaction(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaction deleted"),
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
      _searchFocusNode.requestFocus();
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
      // Payment cancelled, refocus search
      _searchFocusNode.requestFocus();
    }
  }

  Future<void> _processPayment(paymentInfo) async {
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final receiptService = ref.read(receiptServiceProvider);

    // Store the completed checkout for receipt
    final completedCheckout = ref.read(checkoutProvider).activeCheckout;

    try {
      await checkoutNotifier.completeCheckout(paymentInfo);

      if (mounted) {
        // Show success and offer receipt
        await ReceiptPreviewDialog.showPaymentSuccess(
          context,
          checkout: completedCheckout,
          paymentInfo: paymentInfo,
          receiptService: receiptService,
        );

        // Refocus search for next transaction
        _searchFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error during checkout: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _searchFocusNode.requestFocus();
      }
    }
  }
}
