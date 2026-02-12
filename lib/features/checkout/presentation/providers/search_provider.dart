import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/checkout/presentation/utils/item_filter_service.dart';
import 'package:fz_task_1/features/items/domain/entities/item.dart';

import '../models/search_filters.dart';

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

/// All items from repository (domain entities)
final allItemsProvider = Provider<List<Item>>((ref) {
  final itemsState = ref.watch(itemsNotifierProvider);
  return itemsState.items;
});

/// Filtered items based on search and category
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final allItems = ref.watch(allItemsProvider);
  final filters = ref.watch(searchNotifierProvider);

  return ItemFilterHelper.filterItems(
    allItems: allItems,
    filters: filters,
  );
});

/// Available categories
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final allItems = ref.watch(allItemsProvider);
  return ItemFilterHelper.getCategories(allItems);
});
