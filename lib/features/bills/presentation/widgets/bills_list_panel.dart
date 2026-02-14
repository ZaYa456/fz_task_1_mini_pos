import 'package:flutter/material.dart';
import 'package:fz_task_1/features/bills/domain/entities/bill.dart';
import 'package:fz_task_1/features/bills/presentation/widgets/bill_list_item.dart';

/// Panel showing the list of all bills
class BillsListPanel extends StatelessWidget {
  final List<Bill> bills;
  final Bill? selectedBill;
  final Function(Bill) onBillSelected;

  const BillsListPanel({
    super.key,
    required this.bills,
    required this.selectedBill,
    required this.onBillSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bills found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a checkout to see bills here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          final isSelected = selectedBill?.id == bill.id;

          return BillListItem(
            bill: bill,
            isSelected: isSelected,
            onTap: () => onBillSelected(bill),
          );
        },
      ),
    );
  }
}
