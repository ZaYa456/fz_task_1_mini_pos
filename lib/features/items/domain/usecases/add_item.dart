import '../entities/item.dart';
import '../repositories/item_repository.dart';

class AddItem {
  final ItemRepository repository;

  AddItem(this.repository);

  Future<void> call(Item item) {
    return repository.add(item);
  }
}
