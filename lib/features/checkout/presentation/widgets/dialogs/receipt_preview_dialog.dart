import 'package:flutter/material.dart';
import 'package:fz_task_1/features/checkout/domain/entities/checkout.dart';

import '../../../../payments/domain/entities/payment_info.dart';
import '../../../services/receipt_service.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final Checkout checkout;
  final PaymentInfo paymentInfo;
  final ReceiptService receiptService;

  const ReceiptPreviewDialog({
    super.key,
    required this.checkout,
    required this.paymentInfo,
    required this.receiptService,
  });

  @override
  Widget build(BuildContext context) {
    final receiptData = ReceiptData(
      storeName: "YOUR STORE NAME",
      storeAddress: "123 Main St",
      storeCityState: "City, State 12345",
      checkout: checkout,
      paymentInfo: paymentInfo,
    );

    // Assumed synchronous — keep receipt generation pure
    final receiptText = receiptService.generateReceiptText(receiptData);

    return AlertDialog(
      title: const Text("Receipt"),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              receiptText,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Close"),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await receiptService.printReceipt(receiptData);

              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Print failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text("Print"),
        ),
      ],
    );
  }

  /// Shows payment success dialog and optionally receipt preview
  static Future<bool> showPaymentSuccess(
    BuildContext context, {
    required Checkout checkout,
    required PaymentInfo paymentInfo,
    required ReceiptService receiptService,
  }) async {
    final shouldPrint = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text("Payment Complete"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total: \$${paymentInfo.totalDue.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            if (paymentInfo.method == PaymentMethod.cash) ...[
              const SizedBox(height: 8),
              Text(
                "Paid: \$${paymentInfo.amountPaid.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Change: \$${paymentInfo.change.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text("Would you like to print a receipt?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Print Receipt"),
          ),
        ],
      ),
    );

    if (shouldPrint == true) {
      if (!context.mounted) return false;

      await showDialog(
        context: context,
        builder: (context) => ReceiptPreviewDialog(
          checkout: checkout,
          paymentInfo: paymentInfo,
          receiptService: receiptService,
        ),
      );

      if (!context.mounted) return false;

      return true;
    }

    return false;
  }
}
