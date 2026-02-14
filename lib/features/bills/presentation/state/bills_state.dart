import 'package:fz_task_1/features/bills/domain/entities/bill.dart';
import 'package:fz_task_1/features/bills/domain/entities/sort_option.dart';

/// Represents the state of the bills feature
class BillsState {
  final List<Bill> bills;
  final Bill? selectedBill;
  final BillsSortOption sortOption;
  final bool isLoading;
  final String? error;

  const BillsState({
    this.bills = const [],
    this.selectedBill,
    this.sortOption = BillsSortOption.dateDescending,
    this.isLoading = false,
    this.error,
  });

  BillsState copyWith({
    List<Bill>? bills,
    Bill? selectedBill,
    bool clearSelectedBill = false,
    BillsSortOption? sortOption,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BillsState(
      bills: bills ?? this.bills,
      selectedBill:
          clearSelectedBill ? null : (selectedBill ?? this.selectedBill),
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get sorted bills based on current sort option
  List<Bill> get sortedBills {
    final billsList = List<Bill>.from(bills);

    switch (sortOption) {
      case BillsSortOption.dateAscending:
        billsList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case BillsSortOption.dateDescending:
        billsList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case BillsSortOption.totalAscending:
        billsList.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case BillsSortOption.totalDescending:
        billsList.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
    }

    return billsList;
  }

  bool get hasBills => bills.isNotEmpty;
}
