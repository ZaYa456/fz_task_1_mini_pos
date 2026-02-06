import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../items/models/item_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/service_providers.dart';
import '../search_bar_widget.dart';
import 'category_filter_bar.dart';
import 'item_card.dart';

class ItemGridPanel extends ConsumerWidget {
  final FocusNode searchFocusNode;

  const ItemGridPanel({
    super.key,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ---------------- Search Bar ----------------
        Padding(
          padding: const EdgeInsets.all(16),
          child: CheckoutSearchBar(
            focusNode: searchFocusNode,

            // IMPORTANT:
            // Do NOT re-request focus here.
            // Let the root FocusNode own the keyboard.
            onSubmitted: () {
              // Intentionally empty
            },
          ),
        ),

        // ---------------- Category Filters ----------------
        const CategoryFilterBar(),

        const Divider(height: 1),

        // ---------------- Items Grid ----------------
        const Expanded(
          child: _ItemGrid(),
        ),
      ],
    );
  }
}

class _ItemGrid extends ConsumerStatefulWidget {
  const _ItemGrid();

  @override
  ConsumerState<_ItemGrid> createState() => _ItemGridState();
}

class _ItemGridState extends ConsumerState<_ItemGrid> {
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

  void _handleAddItem(Item item) {
    final checkoutService = ref.read(checkoutServiceProvider);
    final cartState = ref.read(checkoutProvider);

    final currentQty = checkoutService.getItemQuantityInCheckout(
      checkout: cartState.activeCheckout,
      item: item,
    );

    if (item.isStockManaged && currentQty >= item.stockQuantity) {
      _showStockWarning(
        'Cannot add more than available stock (${item.stockQuantity})',
      );
      return;
    }

    final success = ref.read(checkoutProvider.notifier).addItem(item);

    if (!success) {
      _showStockWarning(
        'Only ${item.stockQuantity} in stock for ${item.name}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredItemsProvider);

    if (filteredItems.isEmpty) {
      return const Center(
        child: Text('No items found.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];

        return ItemCard(
          item: item,
          onTap: () => _handleAddItem(item),
        );
      },
    );
  }
}
