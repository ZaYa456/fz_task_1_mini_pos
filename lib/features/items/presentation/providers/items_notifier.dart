import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/items/domain/entities/item.dart';
import 'package:fz_task_1/features/items/domain/usecases/add_item.dart';
import 'package:fz_task_1/features/items/domain/usecases/delete_item.dart';
import 'package:fz_task_1/features/items/domain/usecases/get_items.dart';
import 'package:fz_task_1/features/items/domain/usecases/update_item.dart';

/// ----- State ----- ///
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

/// ----- Notifier ----- ///
class ItemsNotifier extends StateNotifier<ItemsState> {
  final GetItems _getItems;
  final AddItem _addItem;
  final UpdateItem _updateItem;
  final DeleteItem _deleteItem;

  ItemsNotifier({
    required GetItems getItems,
    required AddItem addItem,
    required UpdateItem updateItem,
    required DeleteItem deleteItem,
  })  : _getItems = getItems,
        _addItem = addItem,
        _updateItem = updateItem,
        _deleteItem = deleteItem,
        super(const ItemsState(items: [])) {
    _init();
  }

  Future<void> _init() async {
    final items = await _getItems.call();
    state = state.copyWith(items: items);

    _getItems.watch().listen((items) {
      state = state.copyWith(items: items);
    });
  }

  /// ----- Actions ----- ///
  Future<void> addItem(Item item) async => _addItem(item);

  Future<void> updateItem(Item item) async => _updateItem(item);

  Future<void> deleteItem(Item item) async => _deleteItem(item.id);

  /// ----- Utilities ----- ///
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(String field, bool ascending) {
    state = state.copyWith(sortField: field, ascending: ascending);
  }

  /// Returns filtered and sorted items
  List<Item> get filteredItems {
    final filtered = state.items.where(
      (item) =>
          item.name.toLowerCase().contains(state.searchQuery.toLowerCase()),
    );

    final sorted = filtered.toList()
      ..sort((a, b) {
        int cmp;
        if (state.sortField == 'name') {
          cmp = a.name.compareTo(b.name);
        } else {
          cmp = a.price.compareTo(b.price);
        }
        return state.ascending ? cmp : -cmp;
      });

    return sorted;
  }

  /// Check if an item is used in any cart/checkout
  /// Returns a map with keys: isUsed (bool), activeCount, heldCount, totalQuantity
  Future<Map<String, dynamic>> getItemUsage(Item item) async {
    // Placeholder implementation
    // Replace with actual service calls to check item usage
    // For now, just returning dummy data
    return {
      'isUsed': false,
      'activeCount': 0,
      'heldCount': 0,
      'totalQuantity': 0,
    };
  }
}

/// ----- Providers ----- ///
final getItemsProvider = Provider<GetItems>((ref) {
  throw UnimplementedError('Provide GetItems in di.dart');
});
final addItemProvider = Provider<AddItem>((ref) {
  throw UnimplementedError('Provide AddItem in di.dart');
});
final updateItemProvider = Provider<UpdateItem>((ref) {
  throw UnimplementedError('Provide UpdateItem in di.dart');
});
final deleteItemProvider = Provider<DeleteItem>((ref) {
  throw UnimplementedError('Provide DeleteItem in di.dart');
});

final itemsNotifierProvider =
    StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  return ItemsNotifier(
    getItems: ref.watch(getItemsProvider),
    addItem: ref.watch(addItemProvider),
    updateItem: ref.watch(updateItemProvider),
    deleteItem: ref.watch(deleteItemProvider),
  );
});
