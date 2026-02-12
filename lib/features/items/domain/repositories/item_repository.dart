// lib/features/items/domain/repositories/item_repository.dart
import '../entities/item.dart';

abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<Item?> getById(int id);
  Future<void> add(Item item);
  Future<void> update(Item item);
  Future<void> delete(int id);
  
  // New helper for the Checkout feature to use
  Future<void> updateStock(int id, int quantity); 
  
  Stream<List<Item>> watchAll();
}