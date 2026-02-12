import 'package:fz_task_1/features/items/data/models/item_model.dart';
import 'package:hive/hive.dart';

const String kItemBox = 'items_box';

class ItemHiveDataSource {
  static Future<void> init() async {
    Hive.registerAdapter(ItemModelAdapter()); // <- generated adapter
    await Hive.openBox<ItemModel>(kItemBox);
  }
}
