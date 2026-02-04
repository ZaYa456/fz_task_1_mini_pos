import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/payment_info.dart';

class PaymentDialog extends StatefulWidget {
  final double totalDue;

  const PaymentDialog({
    super.key,
    required this.totalDue,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();

  /// Show the payment dialog and return PaymentInfo if completed
  static Future<PaymentInfo?> show(BuildContext context, double totalDue) {
    return showDialog<PaymentInfo>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(totalDue: totalDue),
    );
  }
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'cash';
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.totalDue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amountPaid => double.tryParse(_amountController.text) ?? 0;
  double get _change => _amountPaid - widget.totalDue;

  void _setPaymentMethod(String method) {
    setState(() {
      _paymentMethod = method;
      // Auto-fill exact amount for non-cash payments
      if (method != 'cash') {
        _amountController.text = widget.totalDue.toStringAsFixed(2);
      }
    });
  }

  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  void _completePayment() {
    final paymentInfo = PaymentInfo(
      method: _paymentMethod,
      amountPaid: _amountPaid,
      totalDue: widget.totalDue,
    );

    if (paymentInfo.isValid) {
      Navigator.of(context).pop(paymentInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Payment"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total due
            _TotalDueCard(totalDue: widget.totalDue),

            const SizedBox(height: 24),

            // Payment method selection
            const Text(
              "Payment Method:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Cash"),
                  selected: _paymentMethod == 'cash',
                  onSelected: (selected) => _setPaymentMethod('cash'),
                ),
                ChoiceChip(
                  label: const Text("Card"),
                  selected: _paymentMethod == 'card',
                  onSelected: (selected) => _setPaymentMethod('card'),
                ),
                ChoiceChip(
                  label: const Text("Other"),
                  selected: _paymentMethod == 'other',
                  onSelected: (selected) => _setPaymentMethod('other'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Amount received (only for cash)
            if (_paymentMethod == 'cash') ...[
              const Text(
                "Amount Received:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_change >= 0) {
                    _completePayment();
                  }
                },
              ),

              // Quick amount buttons
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getQuickAmounts().map((amount) {
                  return OutlinedButton(
                    onPressed: () => _setQuickAmount(amount),
                    child: Text("\$$amount"),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Change display
              _ChangeCard(change: _change),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: (_paymentMethod == 'cash' && _change < 0)
              ? null
              : _completePayment,
          child: const Text("Complete Payment"),
        ),
      ],
    );
  }

  List<int> _getQuickAmounts() {
    // Generate smart quick amounts based on total
    final total = widget.totalDue;
    final amounts = <int>[];

    if (total <= 20) {
      amounts.addAll([5, 10, 20]);
    } else if (total <= 50) {
      amounts.addAll([20, 50, 100]);
    } else if (total <= 100) {
      amounts.addAll([50, 100, 200]);
    } else {
      amounts.addAll([100, 200, 500]);
    }

    return amounts;
  }
}

class _TotalDueCard extends StatelessWidget {
  final double totalDue;

  const _TotalDueCard({required this.totalDue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Due:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "\$${totalDue.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final double change;

  const _ChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final isValid = change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isValid ? "Change:" : "Short:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.green[900] : Colors.red[900],
            ),
          ),
          Text(
            "\$${change.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.green[900] : Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }
}
