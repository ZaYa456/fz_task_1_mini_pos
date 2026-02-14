import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/bills/domain/entities/sort_option.dart';
import 'package:fz_task_1/features/bills/presentation/widgets/bill_details_panel.dart';
import 'package:fz_task_1/features/bills/presentation/widgets/bills_list_panel.dart';
import 'package:fz_task_1/features/bills/presentation/widgets/empty_bills_state.dart';

/// Bills page showing list of completed transactions
class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsState = ref.watch(billsNotifierProvider);

    // Listen for errors
    ref.listen(billsNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(billsNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          _buildSortDropdown(context, ref, billsState.sortOption),
          const SizedBox(width: 8),
        ],
      ),
      body: billsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !billsState.hasBills
              ? const EmptyBillsState()
              : _buildBillsContent(context, ref, billsState),
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    WidgetRef ref,
    BillsSortOption currentSort,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<BillsSortOption>(
        value: currentSort,
        dropdownColor: Theme.of(context).colorScheme.surface,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort),
        items: BillsSortOption.values.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option.label),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(billsNotifierProvider.notifier).changeSortOption(value);
          }
        },
      ),
    );
  }

  Widget _buildBillsContent(
    BuildContext context,
    WidgetRef ref,
    billsState,
  ) {
    final sortedBills = billsState.sortedBills;
    final selectedBill = billsState.selectedBill;

    return Row(
      children: [
        // Left: Bills List
        Expanded(
          flex: 2,
          child: BillsListPanel(
            bills: sortedBills,
            selectedBill: selectedBill,
            onBillSelected: (bill) {
              ref.read(billsNotifierProvider.notifier).selectBill(bill);
            },
          ),
        ),

        // Divider
        VerticalDivider(width: 1, color: Colors.grey[300]),

        // Right: Bill Details
        Expanded(
          flex: 3,
          child: BillDetailsPanel(
            bill: selectedBill,
            onDelete: selectedBill != null
                ? () {
                    ref
                        .read(billsNotifierProvider.notifier)
                        .deleteBill(selectedBill.id);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}