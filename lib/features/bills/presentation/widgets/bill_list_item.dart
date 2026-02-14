import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fz_task_1/features/bills/domain/entities/bill.dart';

/// Individual bill item in the list
class BillListItem extends StatelessWidget {
  final Bill bill;
  final bool isSelected;
  final VoidCallback onTap;

  const BillListItem({
    super.key,
    required this.bill,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        title: Text(
          'Bill #${bill.id}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(dateFormat.format(bill.date)),
        trailing: Text(
          '\$${bill.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).primaryColor,
          ),
        ),
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
