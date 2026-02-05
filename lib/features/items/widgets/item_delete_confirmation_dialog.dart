import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemDeleteConfirmationDialog extends StatelessWidget {
  final Item item;
  final Map<String, dynamic> usage;

  const ItemDeleteConfirmationDialog({
    super.key,
    required this.item,
    required this.usage,
  });

  static Future<bool?> show(
    BuildContext context,
    Item item,
    Map<String, dynamic> usage,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ItemDeleteConfirmationDialog(
        item: item,
        usage: usage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = usage['isUsed'] as bool;
    final activeCount = usage['activeCount'] as int;
    final heldCount = usage['heldCount'] as int;
    final totalQuantity = usage['totalQuantity'] as int;

    return AlertDialog(
      title: const Text('Delete Item'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${item.name}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isUsed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning,
                            color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Item In Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This item appears in:',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 4),
                    if (activeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '• Active cart ($totalQuantity ${totalQuantity == 1 ? 'unit' : 'units'})',
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    if (heldCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '• $heldCount held ${heldCount == 1 ? 'transaction' : 'transactions'}',
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The item will be automatically removed from all carts if you proceed.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text(isUsed ? 'Delete Anyway' : 'Delete'),
        ),
      ],
    );
  }
}
