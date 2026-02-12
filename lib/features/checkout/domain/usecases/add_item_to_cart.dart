import 'package:fz_task_1/features/items/domain/repositories/item_repository.dart';
import '../entities/checkout.dart';
import '../entities/checkout_item.dart';
import '../repositories/checkout_repository.dart';

class AddItemToCart {
  final ICheckoutRepository repository;
  final ItemRepository itemRepository;

  AddItemToCart(this.repository, this.itemRepository);

  Future<Checkout> execute({
    required Checkout checkout,
    required int itemId,
    required String itemName,
    required double price,
    required int quantity,
    required bool isStockManaged,
  }) async {
    final items = List<CheckoutItem>.from(checkout.items);
    final existingIndex = items.indexWhere((e) => e.itemId == itemId);
    final currentQtyInCart =
        existingIndex != -1 ? items[existingIndex].quantity : 0;

    // 1. Stock Validation via ItemRepository
    if (isStockManaged) {
      final item = await itemRepository.getById(itemId);

      if (item == null) throw Exception("Item not found in database.");

      if (currentQtyInCart + quantity > item.stockQuantity) {
        throw Exception("Insufficient stock: ${item.stockQuantity} available.");
      }
    }

    // 2. Update or Add logic remains the same
    if (existingIndex != -1) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
    } else {
      items.add(CheckoutItem(
        itemId: itemId,
        itemName: itemName,
        priceAtSale: price,
        quantity: quantity,
      ));
    }

    final updatedCheckout = checkout.copyWith(items: items);
    await repository.saveCheckout(updatedCheckout);

    return updatedCheckout;
  }
}
