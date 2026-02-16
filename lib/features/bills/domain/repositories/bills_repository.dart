import 'package:fz_task_1/features/bills/domain/entities/bill.dart';

/// Abstract repository for bills operations
abstract class BillsRepository {
  /// Get all bills
  List<Bill> getAllBills();

  /// Get a specific bill by ID
  Bill? getBillById(int id);

  /// Delete a bill by ID
  Future<void> deleteBill(int id);

  /// Stream of bills for real-time updates
  Stream<List<Bill>> watchBills();
}
