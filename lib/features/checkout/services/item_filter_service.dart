import '../../items/models/item_model.dart';
import '../models/search_filters.dart';

class ItemFilterService {
  /// Filter items based on search query and category
  List<Item> filterItems({
    required List<Item> allItems,
    required SearchFilters filters,
  }) {
    var filtered = allItems;

    // Apply category filter
    if (filters.selectedCategory != null) {
      filtered = filtered
          .where((item) => item.category == filters.selectedCategory)
          .toList();
    }

    // Apply search query
    if (filters.query.isNotEmpty) {
      final query = filters.query.toLowerCase().trim();
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  /// Try to find item by exact barcode match
  Item? findItemByBarcode({
    required List<Item> allItems,
    required String barcode,
  }) {
    final normalizedBarcode = barcode.toLowerCase().trim();

    return allItems.cast<Item?>().firstWhere(
          (item) => item?.barcode?.toLowerCase() == normalizedBarcode,
          orElse: () => null,
        );
  }

  /// Get unique categories from items
  List<String> getCategories(List<Item> items) {
    return items
        .map((item) => item.category)
        .where((cat) => cat != null && cat.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }
}
