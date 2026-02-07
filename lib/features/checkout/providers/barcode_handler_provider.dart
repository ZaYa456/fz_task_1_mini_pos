import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';
import 'checkout_provider.dart';
import 'search_provider.dart';

/// Barcode handler
class BarcodeHandler {
  final Ref ref;

  BarcodeHandler(this.ref);

  /// Try to process input as barcode
  /// Returns true if barcode was found and item added
  bool tryProcessBarcode(String input) {
    final allItems = ref.read(allItemsProvider);
    final filterService = ref.read(itemFilterServiceProvider);

    final item = filterService.findItemByBarcode(
      allItems: allItems,
      barcode: input,
    );

    if (item != null) {
      // Add item to cart (quantity: null tells it to use pendingQuantity)
      ref.read(checkoutProvider.notifier).addItem(item, quantity: null);

      // Clear search
      ref.read(searchNotifierProvider.notifier).clearQuery();

      return true;
    }

    return false;
  }
}

final barcodeHandlerProvider = Provider<BarcodeHandler>((ref) {
  return BarcodeHandler(ref);
});
