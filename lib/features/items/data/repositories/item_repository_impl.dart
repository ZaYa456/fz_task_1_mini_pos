// lib/features/items/data/repositories/item_repository_impl.dart
import 'package:hive/hive.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../models/item_model.dart';

class ItemRepositoryImpl implements ItemRepository {
  final Box<ItemModel> _itemBox;

  ItemRepositoryImpl(this._itemBox);

  @override
  Future<void> add(Item item) async {
    final model = ItemModel.fromEntity(item);
    // Use 'id' as the Hive key for O(1) access
    await _itemBox.put(item.id, model);
  }

  @override
  Future<void> delete(int id) async {
    // Direct key deletion is faster than finding the object first
    await _itemBox.delete(id);
  }

  @override
  Future<List<Item>> getAll() async {
    return _itemBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Item?> getById(int id) async {
    // O(1) lookup instead of O(n) loop
    final model = _itemBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> update(Item item) async {
    final model = ItemModel.fromEntity(item);
    await _itemBox.put(item.id, model);
  }

  @override
  Future<void> updateStock(int id, int quantity) async {
    final model = _itemBox.get(id);
    if (model != null) {
      model.stockQuantity = quantity;
      await model.save(); // Efficient save since it extends HiveObject
    }
  }

  @override
  Stream<List<Item>> watchAll() {
    return _itemBox
        .watch()
        .map((_) => _itemBox.values.map((e) => e.toEntity()).toList());
  }
}
