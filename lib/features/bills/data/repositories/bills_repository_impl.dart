import 'package:fz_task_1/features/bills/domain/entities/bill.dart';
import 'package:fz_task_1/features/bills/domain/repositories/bills_repository.dart';
import 'package:fz_task_1/features/checkout/data/models/checkout_model.dart';
import 'package:hive/hive.dart';

/// Implementation of bills repository using Hive
class BillsRepositoryImpl implements BillsRepository {
  final Box<CheckoutModel> checkoutBox;

  BillsRepositoryImpl(this.checkoutBox);

  @override
  List<Bill> getAllBills() {
    return checkoutBox.values.map(_checkoutModelToBill).toList();
  }

  @override
  Bill? getBillById(String id) {
    try {
      final checkout = checkoutBox.values.firstWhere(
        (checkout) => checkout.id == id,
      );
      return _checkoutModelToBill(checkout);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteBill(String id) async {
    final checkout = checkoutBox.values.firstWhere(
      (checkout) => checkout.id == id,
    );
    await checkout.delete();
  }

  @override
  Stream<List<Bill>> watchBills() async* {
    yield getAllBills();

    await for (final _ in checkoutBox.watch()) {
      yield getAllBills();
    }
  }

  /// Convert CheckoutModel to Bill entity
  Bill _checkoutModelToBill(CheckoutModel checkout) {
    return Bill(
      id: checkout.id.toString(),
      date: checkout.date,
      totalAmount: checkout.totalAmount,
      items: checkout.items.map((item) {
        return BillItem(
          itemName: item.itemName,
          quantity: item.quantity,
          priceAtSale: item.priceAtSale,
          subtotal: item.quantity * item.priceAtSale,
        );
      }).toList(),
    );
  }
}
