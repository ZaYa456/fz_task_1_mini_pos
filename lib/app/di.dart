// lib/app/di.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/core/database/hive_initializer.dart';
import 'package:fz_task_1/features/checkout/data/models/checkout_model.dart';
import 'package:fz_task_1/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:fz_task_1/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/add_item_to_cart.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/clear_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/complete_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/delete_held_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/get_active_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/get_held_checkouts.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/hold_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/recall_checkout.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/remove_checkout_item.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/remove_item_from_cart.dart';
import 'package:fz_task_1/features/checkout/domain/usecases/set_item_quantity.dart';
import 'package:fz_task_1/features/checkout/services/receipt_service.dart';
import 'package:fz_task_1/features/items/data/models/item_model.dart';
import 'package:fz_task_1/features/items/data/repositories/item_repository_impl.dart';
import 'package:fz_task_1/features/items/domain/repositories/item_repository.dart';
import 'package:fz_task_1/features/items/domain/usecases/add_item.dart';
import 'package:fz_task_1/features/items/domain/usecases/delete_item.dart';
import 'package:fz_task_1/features/items/domain/usecases/get_items.dart';
import 'package:fz_task_1/features/items/domain/usecases/update_item.dart';
import 'package:fz_task_1/features/items/presentation/providers/items_notifier.dart';
import 'package:hive/hive.dart';

// ============================================================================
// ITEMS FEATURE
// ============================================================================

// Hive Box Provider
final itemBoxProvider = Provider<Box<ItemModel>>((ref) {
  return Hive.box<ItemModel>(kItemBox);
});

// Repository Provider
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final box = ref.watch(itemBoxProvider);
  return ItemRepositoryImpl(box);
});

// Use Cases Providers
final getItemsProvider = Provider<GetItems>((ref) {
  return GetItems(ref.watch(itemRepositoryProvider));
});

final addItemProvider = Provider<AddItem>((ref) {
  return AddItem(ref.watch(itemRepositoryProvider));
});

final updateItemProvider = Provider<UpdateItem>((ref) {
  return UpdateItem(ref.watch(itemRepositoryProvider));
});

final deleteItemProvider = Provider<DeleteItem>((ref) {
  return DeleteItem(ref.watch(itemRepositoryProvider));
});

// ItemsNotifier Provider
final itemsNotifierProvider =
    StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  return ItemsNotifier(
    getItems: ref.watch(getItemsProvider),
    addItem: ref.watch(addItemProvider),
    updateItem: ref.watch(updateItemProvider),
    deleteItem: ref.watch(deleteItemProvider),
  );
});

// ============================================================================
// CHECKOUT FEATURE
// ============================================================================

// Hive Box Provider
final checkoutBoxProvider = Provider<Box<CheckoutModel>>((ref) {
  return Hive.box<CheckoutModel>(kCheckoutBox);
});

// Repository Provider - Decoupled from ItemBox
final checkoutRepositoryProvider = Provider<ICheckoutRepository>((ref) {
  final checkoutBox = ref.watch(checkoutBoxProvider);
  return CheckoutRepositoryImpl(checkoutBox);
});

// Use Cases Providers (Cross-Feature: Needs ItemRepository)
final addItemToCartProvider = Provider<AddItemToCart>((ref) {
  return AddItemToCart(
    ref.watch(checkoutRepositoryProvider),
    ref.watch(itemRepositoryProvider),
  );
});

final completeCheckoutProvider = Provider<CompleteCheckout>((ref) {
  return CompleteCheckout(
    ref.watch(checkoutRepositoryProvider),
    ref.watch(itemRepositoryProvider),
  );
});

final setItemQuantityProvider = Provider<SetItemQuantity>((ref) {
  return SetItemQuantity(
    ref.watch(checkoutRepositoryProvider),
    ref.watch(itemRepositoryProvider),
  );
});

// Use Cases Providers (Checkout Only)
final getActiveCheckoutProvider = Provider<GetActiveCheckout>((ref) {
  return GetActiveCheckout(ref.watch(checkoutRepositoryProvider));
});

final getHeldCheckoutsProvider = Provider<GetHeldCheckouts>((ref) {
  return GetHeldCheckouts(ref.watch(checkoutRepositoryProvider));
});

final removeItemFromCartProvider = Provider<RemoveItemFromCart>((ref) {
  return RemoveItemFromCart(ref.watch(checkoutRepositoryProvider));
});

final removeCheckoutItemProvider = Provider<RemoveCheckoutItem>((ref) {
  return RemoveCheckoutItem(ref.watch(checkoutRepositoryProvider));
});

final clearCheckoutProvider = Provider<ClearCheckout>((ref) {
  return ClearCheckout(ref.watch(checkoutRepositoryProvider));
});

final holdCheckoutProvider = Provider<HoldCheckout>((ref) {
  return HoldCheckout(ref.watch(checkoutRepositoryProvider));
});

final recallCheckoutProvider = Provider<RecallCheckout>((ref) {
  return RecallCheckout(ref.watch(checkoutRepositoryProvider));
});

final deleteHeldCheckoutProvider = Provider<DeleteHeldCheckout>((ref) {
  return DeleteHeldCheckout(ref.watch(checkoutRepositoryProvider));
});

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});
