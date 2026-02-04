import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/checkout_items_model.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/stock_validation_provider.dart';

class CartItemRow extends ConsumerStatefulWidget {
  final CheckoutItem item;
  final int index;
  final bool isSelected;

  const CartItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.isSelected,
  });

  @override
  ConsumerState<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<CartItemRow> {
  bool _stockWarningShown = false;

  void _showStockWarning(String message) {
    if (_stockWarningShown) return;

    _stockWarningShown = true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      ).closed.then((_) {
        if (mounted) {
          _stockWarningShown = false;
        }
      });
  }

  void _handleQuantityChange(int newQuantity) {
    final itemBox = ref.read(itemBoxProvider);
    final item = itemBox.get(widget.item.itemId);

    if (item == null) {
      _showStockWarning("Item no longer exists");
      return;
    }

    if (item.isStockManaged && newQuantity > item.stockQuantity) {
      _showStockWarning(
        "Only ${item.stockQuantity} in stock for ${item.name}",
      );
      return;
    }

    final success = ref.read(checkoutProvider.notifier).setItemQuantity(
          widget.item,
          newQuantity,
        );

    if (!success) {
      _showStockWarning(
        "Cannot set quantity higher than available stock",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemBox = ref.watch(itemBoxProvider);
    final item = itemBox.get(widget.item.itemId);

    // Check for stock issues
    final stockIssues = ref.watch(cartStockIssuesProvider);
    final hasIssue = stockIssues
        .any((issue) => issue.checkoutItem.itemId == widget.item.itemId);
    final stockIssue = stockIssues.cast<StockIssue?>().firstWhere(
          (issue) => issue?.checkoutItem.itemId == widget.item.itemId,
          orElse: () => null,
        );

    return InkWell(
      onTap: () {
        ref.read(checkoutProvider.notifier).selectItem(widget.index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasIssue
              ? Colors.red[50]
              : widget.isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasIssue
                ? Colors.red[300]!
                : widget.isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.grey[200]!,
            width: hasIssue || widget.isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Item name and price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.itemName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                decoration: hasIssue && item == null
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasIssue)
                            Icon(
                              Icons.warning,
                              color: Colors.red[700],
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${widget.item.priceAtSale.toStringAsFixed(2)} each",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quantity controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () =>
                          _handleQuantityChange(widget.item.quantity - 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        widget.item.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () =>
                          _handleQuantityChange(widget.item.quantity + 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Total price
                SizedBox(
                  width: 80,
                  child: Text(
                    "\$${(widget.item.priceAtSale * widget.item.quantity).toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  onPressed: () {
                    ref
                        .read(checkoutProvider.notifier)
                        .removeCheckoutItem(widget.item);
                  },
                ),
              ],
            ),

            // Stock issue warning
            if (stockIssue != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red[900]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stockIssue.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
