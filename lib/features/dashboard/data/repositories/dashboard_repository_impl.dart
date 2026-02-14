import 'package:fz_task_1/features/checkout/data/models/checkout_model.dart';
import 'package:fz_task_1/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:fz_task_1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fz_task_1/features/items/data/models/item_model.dart';
import 'package:hive/hive.dart';

/// Implementation of dashboard repository using Hive boxes
class DashboardRepositoryImpl implements DashboardRepository {
  final Box<ItemModel> itemBox;
  final Box<CheckoutModel> checkoutBox;

  DashboardRepositoryImpl({
    required this.itemBox,
    required this.checkoutBox,
  });

  @override
  DashboardStats getStats() {
    final itemCount = itemBox.length;
    final billCount = checkoutBox.length;

    final totalSales = checkoutBox.values.fold(
      0.0,
      (sum, bill) => sum + bill.totalAmount,
    );

    return DashboardStats(
      itemCount: itemCount,
      billCount: billCount,
      totalSales: totalSales,
    );
  }

  @override
  Stream<DashboardStats> watchStats() async* {
    // Initial stats
    yield getStats();

    // Watch for changes in both boxes
    await for (final _ in _combineBoxStreams()) {
      yield getStats();
    }
  }

  Stream<void> _combineBoxStreams() async* {
    final itemStream = itemBox.watch();
    final checkoutStream = checkoutBox.watch();

    await for (final _ in itemStream) {
      yield null;
    }

    await for (final _ in checkoutStream) {
      yield null;
    }
  }
}
