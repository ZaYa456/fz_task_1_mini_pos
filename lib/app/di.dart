import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/core/database/hive_initializer.dart';
import 'package:fz_task_1/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fz_task_1/features/auth/data/models/user_model.dart';
import 'package:fz_task_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fz_task_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:fz_task_1/features/auth/domain/usecases/get_current_user.dart';
import 'package:fz_task_1/features/auth/domain/usecases/login.dart';
import 'package:fz_task_1/features/auth/domain/usecases/logout.dart';
import 'package:fz_task_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:fz_task_1/features/auth/presentation/state/auth_state.dart';
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
import 'package:fz_task_1/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fz_task_1/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:fz_task_1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fz_task_1/features/dashboard/domain/usecases/get_dashboard_stats.dart';
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
// AUTH FEATURE
// ============================================================================

// Hive Box Provider
final userBoxProvider = Provider<Box<UserModel>>((ref) {
  return Hive.box<UserModel>(kUserBox);
});

// Provider for Preferences Box (used for session management)
final preferencesBoxProvider = Provider<Box>((ref) {
  return Hive.box(kPreferencesBox); // Get untyped box
});

// Update the dataSource provider:
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final userBox = ref.watch(userBoxProvider);
  final preferencesBox = ref.watch(preferencesBoxProvider); // Add this

  return AuthLocalDataSourceImpl(
    userBox: userBox,
    preferencesBox: preferencesBox, // Pass it
  );
});

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// Use Cases Providers
final loginUseCaseProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

// Auth State Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});

// ============================================================================
// DASHBOARD FEATURE
// ============================================================================

// Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final itemBox = ref.watch(itemBoxProvider);
  final checkoutBox = ref.watch(checkoutBoxProvider);

  return DashboardRepositoryImpl(
    itemBox: itemBox,
    checkoutBox: checkoutBox,
  );
});

// Use Case Provider
final getDashboardStatsUseCaseProvider = Provider<GetDashboardStats>((ref) {
  return GetDashboardStats(ref.watch(dashboardRepositoryProvider));
});

// Stats Provider - now using the use case
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final useCase = ref.watch(getDashboardStatsUseCaseProvider);
  return useCase();
});

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

// Repository Provider
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

// Services
final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});
