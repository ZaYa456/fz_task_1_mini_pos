import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/checkout/presentation/providers/stock_validation_provider.dart';

import '../../providers/checkout_provider.dart';
import 'cart_item_row.dart';
import 'cart_total_section.dart';

class CartSummaryPanel extends ConsumerWidget {
  final VoidCallback onHold;
  final VoidCallback onPay;

  const CartSummaryPanel({
    super.key,
    required this.onHold,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(checkoutProvider);
    final items = cartState.activeCheckout.items;
    final selectedIndex = cartState.selectedItemIndex;
    final hasStockIssues = ref.watch(hasStockIssuesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Header
          _CartHeader(itemCount: items.length),

          // Stock issues banner
          if (hasStockIssues) _StockIssuesBanner(),

          // Column headers
          _ColumnHeaders(),

          // Cart items list
          Expanded(
            child: items.isEmpty
                ? _EmptyCart()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return CartItemRow(
                        item: item,
                        index: index,
                        isSelected: selectedIndex == index,
                      );
                    },
                  ),
          ),

          // Total and actions
          CartTotalSection(
            onHold: onHold,
            onPay: onPay,
          ),
        ],
      ),
    );
  }
}

class _StockIssuesBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(cartStockIssuesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(
          bottom: BorderSide(color: Colors.red[200]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${issues.length} ${issues.length == 1 ? 'item has' : 'items have'} stock issues. Remove or adjust before checkout.',
              style: TextStyle(
                color: Colors.red[900],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final int itemCount;

  const _CartHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, size: 24),
          const SizedBox(width: 12),
          const Text(
            "Cart",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: itemCount == 0
                  ? Colors.grey[300]
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$itemCount ${itemCount == 1 ? 'item' : 'items'}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: itemCount == 0
                    ? Colors.grey[700]
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "Item",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              "Qty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              "Total",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Scan or add items to get started",
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
