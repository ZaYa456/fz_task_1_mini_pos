import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/models/item_model.dart';
import '../models/checkout_items_model.dart';
import 'checkout_provider.dart';
import 'service_providers.dart';

/// Represents items in cart that have stock issues
class StockIssue {
  final CheckoutItem checkoutItem;
  final Item? item;
  final String message;
  final StockIssueType type;

  const StockIssue({
    required this.checkoutItem,
    required this.item,
    required this.message,
    required this.type,
  });
}

enum StockIssueType {
  outOfStock, // Item is completely out of stock
  insufficientStock, // Cart has more than available stock
  itemDeleted, // Item no longer exists
}

/// Provider that checks for stock issues in the current cart
final cartStockIssuesProvider = Provider<List<StockIssue>>((ref) {
  final cartState = ref.watch(checkoutProvider);
  final itemBox = ref.watch(itemBoxProvider);

  final issues = <StockIssue>[];

  for (final checkoutItem in cartState.activeCheckout.items) {
    final item = itemBox.get(checkoutItem.itemId);

    // Item was deleted
    if (item == null) {
      issues.add(StockIssue(
        checkoutItem: checkoutItem,
        item: null,
        message: '${checkoutItem.itemName} no longer exists',
        type: StockIssueType.itemDeleted,
      ));
      continue;
    }

    // Not stock managed - skip
    if (!item.isStockManaged) continue;

    // Out of stock
    if (item.stockQuantity <= 0) {
      issues.add(StockIssue(
        checkoutItem: checkoutItem,
        item: item,
        message: '${item.name} is out of stock',
        type: StockIssueType.outOfStock,
      ));
      continue;
    }

    // Insufficient stock
    if (checkoutItem.quantity > item.stockQuantity) {
      issues.add(StockIssue(
        checkoutItem: checkoutItem,
        item: item,
        message:
            '${item.name}: only ${item.stockQuantity} available, ${checkoutItem.quantity} in cart',
        type: StockIssueType.insufficientStock,
      ));
    }
  }

  return issues;
});

/// Provider that checks if cart has any stock issues
final hasStockIssuesProvider = Provider<bool>((ref) {
  return ref.watch(cartStockIssuesProvider).isNotEmpty;
});
