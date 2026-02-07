import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../items/models/item_model.dart';
import '../../providers/checkout_provider.dart';

class ItemCard extends ConsumerWidget {
  final Item item;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the entire cart state to react to any changes
    final cartState = ref.watch(checkoutProvider);

    // Calculate quantity from the current cart state
    final qty = cartState.activeCheckout.items
        .where((e) => e.itemId == item.key)
        .fold<int>(0, (sum, e) => sum + e.quantity);

    final isLowStock = item.isStockManaged &&
        item.stockQuantity <= 5 &&
        item.stockQuantity > 0;
    final isOutOfStock = item.isStockManaged && item.stockQuantity <= 0;

    return Card(
      elevation: qty > 0 ? 4 : 1,
      color: isOutOfStock
          ? Colors.grey[200]
          : qty > 0
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
      child: InkWell(
        onTap: isOutOfStock
            ? null
            : () {
                onTap?.call(); // ONLY notify parent to add item to cart, do NOT modify cart state here
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item name
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isOutOfStock ? Colors.grey : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                "\$${item.price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 4),

              // Stock info
              if (item.isStockManaged)
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 12,
                      color: isOutOfStock
                          ? Colors.red
                          : isLowStock
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOutOfStock ? "Out of stock" : "${item.stockQuantity}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.grey[600],
                        fontWeight:
                            isLowStock || isOutOfStock ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),

              // In cart indicator
              if (qty > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "×$qty in cart",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
