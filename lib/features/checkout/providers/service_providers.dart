import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../items/models/item_model.dart';
import '../models/checkout_model.dart';
import '../../../services/hive_setup.dart';
import '../services/checkout_service.dart';
import '../services/transaction_manager.dart';
import '../services/receipt_service.dart';
import '../services/item_filter_service.dart';

/// Hive box providers
final itemBoxProvider = Provider<Box<Item>>((ref) {
  return Hive.box<Item>(kItemBox);
});

final checkoutBoxProvider = Provider<Box<Checkout>>((ref) {
  return Hive.box<Checkout>(kCheckoutBox);
});

/// Service providers
final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final itemBox = ref.watch(itemBoxProvider);
  final checkoutBox = ref.watch(checkoutBoxProvider);
  return CheckoutService(itemBox, checkoutBox);
});

final transactionManagerProvider = Provider<TransactionManager>((ref) {
  final checkoutBox = ref.watch(checkoutBoxProvider);
  return TransactionManager(checkoutBox);
});

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});

final itemFilterServiceProvider = Provider<ItemFilterService>((ref) {
  return ItemFilterService();
});
