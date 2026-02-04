import 'package:flutter/material.dart';

class ClearCartDialog extends StatelessWidget {
  const ClearCartDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Clear Cart"),
      content: const Text("Are you sure you want to clear all items?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Clear"),
        ),
      ],
    );
  }

  /// Show clear cart confirmation dialog
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ClearCartDialog(),
    );
    return result ?? false;
  }
}
