import '../repositories/item_repository.dart';

class DeleteItem {
  final ItemRepository repository;

  DeleteItem(this.repository);

  Future<void> call(int id) {
    return repository.delete(id);
  }
}
