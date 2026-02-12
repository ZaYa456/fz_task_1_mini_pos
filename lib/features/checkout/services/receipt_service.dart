import 'package:fz_task_1/features/checkout/domain/entities/checkout.dart';
import 'package:fz_task_1/features/payments/domain/entities/payment_info.dart';

class ReceiptData {
  final String storeName;
  final String storeAddress;
  final String storeCityState;
  final Checkout checkout;
  final PaymentInfo paymentInfo;

  const ReceiptData({
    required this.storeName,
    required this.storeAddress,
    required this.storeCityState,
    required this.checkout,
    required this.paymentInfo,
  });
}

/// Infrastructure service for receipt generation and printing
class ReceiptService {
  /// Generate receipt text
  String generateReceiptText(ReceiptData data) {
    final buffer = StringBuffer();
    final checkout = data.checkout;
    final payment = data.paymentInfo;

    // Header
    buffer.writeln(data.storeName.toUpperCase());
    buffer.writeln(data.storeAddress);
    buffer.writeln(data.storeCityState);
    buffer.writeln('=' * 40);

    // Transaction info
    buffer.writeln('Date: ${_formatDateTime(checkout.date)}');
    buffer.writeln('Transaction #${checkout.id}');
    buffer.writeln('-' * 40);

    // Items
    for (final item in checkout.items) {
      final itemTotal = item.priceAtSale * item.quantity;
      buffer.writeln(
        '${item.itemName} x${item.quantity}',
      );
      buffer.writeln(
        '  \$${item.priceAtSale.toStringAsFixed(2)} ea  '
        '\$${itemTotal.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('-' * 40);

    // Totals
    buffer.writeln(
      '${'Subtotal:'.padRight(30)}\$${checkout.totalAmount.toStringAsFixed(2)}',
    );

    // Payment details
    if (payment.method == 'cash') {
      buffer.writeln(
        '${'Cash:'.padRight(30)}\$${payment.amountPaid.toStringAsFixed(2)}',
      );
      buffer.writeln(
        '${'Change:'.padRight(30)}\$${payment.change.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('=' * 40);
    buffer.writeln('Payment: ${payment.method}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln('Thank you for your business!');

    return buffer.toString();
  }

  /// Print receipt (implement with actual printer integration)
  Future<void> printReceipt(ReceiptData data) async {
    // TODO: Implement actual printer integration
    // For now, this is a placeholder
    final receiptText = generateReceiptText(data);
    print(receiptText); // Debug output

    // Future implementation could use packages like:
    // - esc_pos_printer for thermal printers
    // - pdf for generating PDF receipts
    // - printing for system printers
  }

  /// Format DateTime for receipt
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
