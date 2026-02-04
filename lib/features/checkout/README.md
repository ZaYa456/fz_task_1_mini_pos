# Checkout Feature

Refactored POS checkout system with clean architecture and state management.

## Structure

checkout/
├── models/ # Data models and DTOs
├── providers/ # Riverpod state management
├── services/ # Business logic layer
├── widgets/ # UI components
│ ├── cart_summary/ # Cart display widgets
│ ├── item_grid/ # Item selection widgets
│ └── dialogs/ # Dialog components
└── checkout_page.dart # Main page (orchestration only)

## Key Features

- **Barcode Scanner Support**: Auto-focuses search, detects barcodes
- **Keyboard Shortcuts**: F1-F12 for common actions
- **Hold/Recall**: Multi-transaction support
- **Payment Flow**: Change calculation, receipt generation
- **State Management**: Riverpod for reactive updates
- **Clean Architecture**: Services, providers, widgets separated

## Keyboard Shortcuts

- `F1` - Hold current transaction
- `F2` - Recall held transaction
- `F9` - Clear cart
- `F12` - Show payment dialog
- `Delete` - Remove selected item
- `↑/↓` - Navigate cart items
- `+/-` - Adjust quantity of selected item

## Usage

```dart
import 'package:your_app/features/checkout/checkout.dart';

// Navigate to checkout
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CheckoutPage()),
);
```
