import 'checkout_model.dart';

class CartState {
  final Checkout activeCheckout;
  final List<Checkout> heldCheckouts;
  final int? selectedItemIndex;
  final bool isProcessing;

  const CartState({
    required this.activeCheckout,
    this.heldCheckouts = const [],
    this.selectedItemIndex,
    this.isProcessing = false,
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
  }) {
    return CartState(
      activeCheckout: activeCheckout ?? this.activeCheckout,
      heldCheckouts: heldCheckouts ?? this.heldCheckouts,
      selectedItemIndex: selectedItemIndex != null
          ? selectedItemIndex()
          : this.selectedItemIndex,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
