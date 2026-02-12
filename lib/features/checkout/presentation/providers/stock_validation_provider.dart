import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/items/domain/entities/item.dart';

import '../../domain/entities/checkout_item.dart';
import 'checkout_provider.dart';

/// Represents items in cart that have stock issues
class StockIssue {
  final CheckoutItem checkoutItem;
  final Item? item; // null if item was deleted
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
/// Watches BOTH cart changes AND items provider changes
final cartStockIssuesProvider = Provider<List<StockIssue>>((ref) {
  // Get cart state
  final cartState = ref.watch(checkoutProvider);

  // Get all items from domain (this is the correct way)
  final itemsState = ref.watch(itemsNotifierProvider);
  final allItems = itemsState.items;

  final issues = <StockIssue>[];

  // Check each item in cart
  for (final checkoutItem in cartState.activeCheckout.items) {
    // Find the actual item by ID
    final item = allItems.cast<Item?>().firstWhere(
          (i) => i?.id == checkoutItem.itemId,
          orElse: () => null,
        );

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

/// State provider for tracking recently removed items (for notifications)
final recentlyRemovedItemsProvider = StateProvider<List<String>>((ref) => []);
