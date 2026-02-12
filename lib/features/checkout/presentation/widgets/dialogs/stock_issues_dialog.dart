import 'package:flutter/material.dart';

import '../../providers/stock_validation_provider.dart';

class StockIssuesDialog extends StatelessWidget {
  final List<StockIssue> issues;

  const StockIssuesDialog({
    super.key,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text("Stock Issues Detected"),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The following items in your cart have stock issues:",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ...issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Auto-fix will adjust quantities to match available stock or remove out-of-stock items.",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Auto-Fix"),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required List<StockIssue> issues,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => StockIssuesDialog(
        issues: issues,
      ),
    );
  }
}
