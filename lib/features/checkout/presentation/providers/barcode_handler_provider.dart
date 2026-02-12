import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/checkout/presentation/utils/item_filter_service.dart';

import 'checkout_provider.dart';
import 'search_provider.dart';

/// Barcode handler
class BarcodeHandler {
  final Ref ref;

  BarcodeHandler(this.ref);

  /// Try to process input as barcode
  /// Returns true if barcode was found and item added
  Future<bool> tryProcessBarcode(String input) async {
    final allItems = ref.read(allItemsProvider);

    final item = ItemFilterHelper.findItemByBarcode(
      allItems: allItems,
      barcode: input,
    );

    if (item != null) {
      // Add item to cart (quantity: null tells it to use pendingQuantity)
      final success = await ref.read(checkoutProvider.notifier).addItem(
            item,
            quantity: null,
          );

      if (success) {
        // Clear search
        ref.read(searchNotifierProvider.notifier).clearQuery();
        return true;
      }
    }

    return false;
  }
}

final barcodeHandlerProvider = Provider<BarcodeHandler>((ref) {
  return BarcodeHandler(ref);
});
