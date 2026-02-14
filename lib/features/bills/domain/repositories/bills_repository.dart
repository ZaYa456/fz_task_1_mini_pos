import 'package:fz_task_1/features/bills/domain/entities/bill.dart';

/// Abstract repository for bills operations
abstract class BillsRepository {
  /// Get all bills
  List<Bill> getAllBills();

  /// Get a specific bill by ID
  Bill? getBillById(String id);

  /// Delete a bill by ID
  Future<void> deleteBill(String id);

  /// Stream of bills for real-time updates
  Stream<List<Bill>> watchBills();
}
