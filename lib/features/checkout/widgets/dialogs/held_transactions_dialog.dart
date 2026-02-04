import 'package:flutter/material.dart';

import '../../models/checkout_model.dart';

class HeldTransactionsDialog extends StatelessWidget {
  final List<Checkout> heldCheckouts;
  final Function(int index) onRecall;
  final Function(int index) onDelete;

  const HeldTransactionsDialog({
    super.key,
    required this.heldCheckouts,
    required this.onRecall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (heldCheckouts.isEmpty) {
      return AlertDialog(
        title: const Text("Held Transactions"),
        content: const Text("No held transactions available."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text("Held Transactions"),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: heldCheckouts.length,
          itemBuilder: (context, index) {
            final checkout = heldCheckouts[index];
            return _HeldTransactionTile(
              checkout: checkout,
              onTap: () {
                Navigator.of(context).pop();
                onRecall(index);
              },
              onDelete: () {
                onDelete(index);
                // Close dialog if no more held transactions
                if (heldCheckouts.length == 1) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  /// Show the held transactions dialog
  static Future<void> show(
    BuildContext context, {
    required List<Checkout> heldCheckouts,
    required Function(int index) onRecall,
    required Function(int index) onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => HeldTransactionsDialog(
        heldCheckouts: heldCheckouts,
        onRecall: onRecall,
        onDelete: onDelete,
      ),
    );
  }
}

class _HeldTransactionTile extends StatelessWidget {
  final Checkout checkout;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HeldTransactionTile({
    required this.checkout,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          "${checkout.items.length} items - \$${checkout.totalAmount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Held at ${TimeOfDay.fromDateTime(checkout.date).format(context)}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _confirmDelete(context);
          },
          tooltip: "Delete transaction",
        ),
        onTap: onTap,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text(
          "Are you sure you want to delete this held transaction? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
