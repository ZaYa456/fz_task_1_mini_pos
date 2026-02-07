import 'checkout_model.dart';

class CartState {
  final Checkout activeCheckout;
  final List<Checkout> heldCheckouts;
  final int? selectedItemIndex;
  final bool isProcessing;
  final int pendingQuantity; // Pending quantity for next item
  final bool isDefaultQuantity; // True if pendingQuantity is still the default (1) and hasn't been typed yet

  const CartState({
    required this.activeCheckout,
    this.heldCheckouts = const [],
    this.selectedItemIndex,
    this.isProcessing = false,
    this.pendingQuantity = 1,
    this.isDefaultQuantity = true,
  });

  bool get isEmpty => activeCheckout.items.isEmpty;

  double get subtotal => activeCheckout.items.fold(
        0,
        (sum, item) => sum + (item.priceAtSale * item.quantity),
      );

  double get tax => subtotal * 0.0; // Configure as needed

  double get total => subtotal + tax;

  int get itemCount => activeCheckout.items.length;

  CartState copyWith({
    Checkout? activeCheckout,
    List<Checkout>? heldCheckouts,
    int? Function()? selectedItemIndex,
    bool? isProcessing,
    int? pendingQuantity,
    bool? isDefaultQuantity,
  }) {
    return CartState(
      activeCheckout: activeCheckout ?? this.activeCheckout,
      heldCheckouts: heldCheckouts ?? this.heldCheckouts,
      selectedItemIndex: selectedItemIndex != null
          ? selectedItemIndex()
          : this.selectedItemIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingQuantity: pendingQuantity ?? this.pendingQuantity,
      isDefaultQuantity: isDefaultQuantity ?? this.isDefaultQuantity,
    );
  }
}
