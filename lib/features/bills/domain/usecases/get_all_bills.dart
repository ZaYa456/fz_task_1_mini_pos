import 'package:fz_task_1/features/bills/domain/entities/bill.dart';
import 'package:fz_task_1/features/bills/domain/repositories/bills_repository.dart';

/// Use case for retrieving all bills
class GetAllBills {
  final BillsRepository repository;

  GetAllBills(this.repository);

  /// Get all bills from repository
  List<Bill> call() {
    return repository.getAllBills();
  }
}
