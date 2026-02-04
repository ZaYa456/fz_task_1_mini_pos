import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/models/item_model.dart';
import '../models/search_filters.dart';
import 'service_providers.dart';

/// Search controller notifier
class SearchNotifier extends StateNotifier<SearchFilters> {
  SearchNotifier() : super(const SearchFilters());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: () => category,
    );
  }

  void clearQuery() {
    state = state.clearQuery();
  }

  void clearCategory() {
    state = state.clearCategory();
  }

  void clearAll() {
    state = state.clear();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchFilters>((ref) {
  return SearchNotifier();
});

/// All items from Hive
final allItemsProvider = Provider<List<Item>>((ref) {
  final itemBox = ref.watch(itemBoxProvider);
  return itemBox.values.toList();
});

/// Filtered items based on search and category
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final allItems = ref.watch(allItemsProvider);
  final filters =
      ref.watch(searchNotifierProvider); // Changed from searchFiltersProvider
  final filterService = ref.watch(itemFilterServiceProvider);

  return filterService.filterItems(
    allItems: allItems,
    filters: filters,
  );
});

/// Available categories
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final allItems = ref.watch(allItemsProvider);
  final filterService = ref.watch(itemFilterServiceProvider);

  return filterService.getCategories(allItems);
});
