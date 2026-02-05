import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/items/models/item_model.dart';
import 'package:fz_task_1/features/items/services/item_service.dart';
import 'package:fz_task_1/services/hive_setup.dart';
import 'package:fz_task_1/features/checkout/models/checkout_model.dart';
import 'package:hive/hive.dart';

class ItemsState {
  final List<Item> items;
  final String searchQuery;
  final String sortField;
  final bool ascending;

  const ItemsState({
    required this.items,
    this.searchQuery = '',
    this.sortField = 'name',
    this.ascending = true,
  });

  ItemsState copyWith({
    List<Item>? items,
    String? searchQuery,
    String? sortField,
    bool? ascending,
  }) {
    return ItemsState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
    );
  }
}

class ItemsNotifier extends StateNotifier<ItemsState> {
  final ItemService _service;

  ItemsNotifier(this._service) : super(ItemsState(items: _service.getAll())) {
    _service.watch().listen((_) {
      _reload();
    });
  }

  void _reload() {
    final newItems = _service.getAll();

    if (state.items.length == newItems.length) {
      // Optional: Add deeper equality check if needed
      // return;
    }

    state = state.copyWith(items: newItems);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(String field, bool ascending) {
    state = state.copyWith(sortField: field, ascending: ascending);
  }

  /// Auto-fix stock issues by adjusting quantities or removing items
  void autoFixStockIssues() {
    final items = _service.getAll();
    bool changed = false;

    for (var item in items) {
      if (item.stockQuantity < 0) {
        item.stockQuantity = 0;
        item.save();
        changed = true;
      }
    }
  }

  Future<void> addItem(Item item) async {
    await _service.add(item);
  }

  Future<void> updateItem(Item item) async {
    await _service.update(item);
  }

  /// Check if item can be deleted (returns usage info)
  Map<String, dynamic> checkItemUsage(Item item) {
    return _service.getItemUsage(item);
  }

  /// Delete item and remove from all checkouts
  Future<void> deleteItem(Item item) async {
    // First remove from all checkouts
    await _service.removeItemFromAllCheckouts(item);

    // Then delete the item
    await _service.delete(item);
  }

  List<Item> get filteredItems {
    final filtered = state.items.where(
      (item) =>
          item.name.toLowerCase().contains(state.searchQuery.toLowerCase()),
    );

    final sorted = filtered.toList()
      ..sort((a, b) {
        final cmp = state.sortField == 'name'
            ? a.name.compareTo(b.name)
            : a.price.compareTo(b.price);
        return state.ascending ? cmp : -cmp;
      });

    return sorted;
  }
}

final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(
    Hive.box<Item>(kItemBox),
    Hive.box<Checkout>(kCheckoutBox),
  );
});

final itemsProvider = StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  return ItemsNotifier(ref.watch(itemServiceProvider));
});
