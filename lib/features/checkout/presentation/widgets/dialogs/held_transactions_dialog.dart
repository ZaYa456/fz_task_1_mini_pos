import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/checkout/presentation/providers/checkout_provider.dart';

class HeldTransactionsDialog extends ConsumerWidget {
  const HeldTransactionsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(checkoutProvider);
    final heldCheckouts = cartState.heldCheckouts;

    // Auto-close dialog when list becomes empty
    ref.listen(checkoutProvider, (previous, next) {
      if (previous?.heldCheckouts.isNotEmpty == true &&
          next.heldCheckouts.isEmpty) {
        Navigator.of(context).pop();
      }
    });

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
                  onPressed: () => _confirmDelete(context, ref, index),
                ),
                onTap: () async {
                  await ref
                      .read(checkoutProvider.notifier)
                      .recallTransaction(index);

                  Navigator.of(context).pop();
                },
              ),
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

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () async {
              Navigator.of(context).pop();

              await ref
                  .read(checkoutProvider.notifier)
                  .deleteHeldTransaction(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // Simplified show method
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const HeldTransactionsDialog(),
    );
  }
}
