import '../../domain/entities/checkout.dart';

class CartState {
  final Checkout activeCheckout;
  final List<Checkout> heldCheckouts;
  final bool transactionJustRecalled; // Resets after one frame
  final int? selectedItemIndex;
  final bool isProcessing;
  final int pendingQuantity;
  final bool isDefaultQuantity;

  const CartState({
    required this.activeCheckout,
    this.heldCheckouts = const [],
    this.transactionJustRecalled = false,
    this.selectedItemIndex,
    this.isProcessing = false,
    this.pendingQuantity = 1,
    this.isDefaultQuantity = true,
  });

  /// Initial state factory
  factory CartState.initial() {
    return CartState(
      activeCheckout: Checkout(
        id: DateTime.now().millisecondsSinceEpoch,
        date: DateTime.now(),
        items: [],
      ),
      heldCheckouts: [],
      transactionJustRecalled: false,
      selectedItemIndex: null,
    );
  }

  // Computed properties
  bool get isEmpty => activeCheckout.isEmpty;
  int get itemCount => activeCheckout.items.length;
  double get subtotal => activeCheckout.subtotal;
  double get total => activeCheckout.totalAmount;

  CartState copyWith({
    Checkout? activeCheckout,
    List<Checkout>? heldCheckouts,
    bool? transactionJustRecalled,
    int? selectedItemIndex,
    bool? isProcessing,
    int? pendingQuantity,
    bool? isDefaultQuantity,
  }) {
    return CartState(
      activeCheckout: activeCheckout ?? this.activeCheckout,
      heldCheckouts: heldCheckouts ?? this.heldCheckouts,
      transactionJustRecalled: transactionJustRecalled ?? false, // Auto-reset
      selectedItemIndex: selectedItemIndex ?? this.selectedItemIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingQuantity: pendingQuantity ?? this.pendingQuantity,
      isDefaultQuantity: isDefaultQuantity ?? this.isDefaultQuantity,
    );
  }
}
