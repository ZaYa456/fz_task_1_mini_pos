import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/bills/domain/entities/bill.dart';
import 'package:fz_task_1/features/bills/domain/entities/sort_option.dart';
import 'package:fz_task_1/features/bills/domain/usecases/delete_bill.dart';
import 'package:fz_task_1/features/bills/domain/usecases/get_all_bills.dart';
import 'package:fz_task_1/features/bills/presentation/state/bills_state.dart';

/// Notifier that manages bills state
class BillsNotifier extends StateNotifier<BillsState> {
  final GetAllBills getAllBillsUseCase;
  final DeleteBill deleteBillUseCase;

  BillsNotifier({
    required this.getAllBillsUseCase,
    required this.deleteBillUseCase,
  }) : super(const BillsState()) {
    loadBills();
  }

  /// Load all bills
  void loadBills() {
    try {
      final bills = getAllBillsUseCase();

      // Auto-select the most recent bill
      final selectedBill = bills.isNotEmpty
          ? bills.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          : null;

      state = state.copyWith(
        bills: bills,
        selectedBill: selectedBill,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load bills: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Select a bill to view details
  void selectBill(Bill bill) {
    state = state.copyWith(selectedBill: bill);
  }

  /// Change sort option
  void changeSortOption(BillsSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      await deleteBillUseCase(billId);

      // Reload bills after deletion
      loadBills();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete bill: ${e.toString()}',
      );
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
