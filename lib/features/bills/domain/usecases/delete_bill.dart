import 'package:fz_task_1/features/bills/domain/repositories/bills_repository.dart';

/// Use case for deleting a bill
class DeleteBill {
  final BillsRepository repository;

  DeleteBill(this.repository);

  /// Delete a bill by its ID
  Future<void> call(String billId) async {
    await repository.deleteBill(billId);
  }
}
