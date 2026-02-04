import 'package:hive/hive.dart';
import '../models/item_model.dart';

class ItemService {
  final Box<Item> _itemBox;

  ItemService(this._itemBox);

  List<Item> getAll() => _itemBox.values.toList();

  Future<void> add(Item item) => _itemBox.add(item);

  Future<void> update(Item item) => item.save();

  Future<void> delete(Item item) => item.delete();

  Stream<void> watch() => _itemBox.watch().map((_) {});
}
