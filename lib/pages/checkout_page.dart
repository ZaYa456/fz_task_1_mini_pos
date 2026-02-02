import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_setup.dart';
import '../models/item_model.dart';
import '../models/checkout_model.dart';
import '../models/checkout_items_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Box<Item> _itemBox;
  late Box<Checkout> _checkoutBox;

  Checkout? _activeCheckout;
  CheckoutItem? _selectedCartItem;

  bool _isProcessing = false;
  bool _stockWarningShown = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];

  // ---------------- Lifecycle ----------------

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<Item>(kItemBox);
    _checkoutBox = Hive.box<Checkout>(kCheckoutBox);

    _filteredItems = _itemBox.values.toList();
    _searchController.addListener(_applySearch);

    _loadOrCreateActiveCheckout();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- Checkout Handling ----------------

  void _loadOrCreateActiveCheckout() {
    _activeCheckout = _checkoutBox.values.firstWhere(
      (c) => c.status == 'open',
      orElse: _createNewCheckout,
    );
  }

  Checkout _createNewCheckout() {
    final checkout = Checkout()
      ..id = DateTime.now().millisecondsSinceEpoch
      ..date = DateTime.now()
      ..items = []
      ..totalAmount = 0
      ..status = 'open';

    _checkoutBox.add(checkout);
    return checkout;
  }

  void _recalculateAndSaveCheckout() {
    if (_activeCheckout == null) return;

    _activeCheckout!
      ..totalAmount = _total
      ..save();

    setState(() {});
  }

  // ---------------- Search ----------------

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _itemBox.values
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    });
  }

  // ---------------- Cart Helpers ----------------

  double get _total {
    return _activeCheckout?.items.fold(
          0,
          (sum, e) => sum! + e.priceAtSale * e.quantity,
        ) ??
        0;
  }

  bool get _isCartEmpty =>
      _activeCheckout == null || _activeCheckout!.items.isEmpty;

  int _quantityForItem(Item item) {
    final entry = _activeCheckout!.items.cast<CheckoutItem?>().firstWhere(
          (e) => e?.itemId == item.key,
          orElse: () => null,
        );
    return entry?.quantity ?? 0;
  }

  // ---------------- Stock-aware quantity setter ----------------

  void _setQuantityWithStockCheck(CheckoutItem entry, int newQty) {
    final item = _itemBox.get(entry.itemId);

    if (item == null) return;

    if (item.isStockManaged && newQty > item.stockQuantity) {
      if (!_stockWarningShown) {
        _stockWarningShown = true;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                "Only ${item.stockQuantity} in stock for ${item.name}",
              ),
              duration: const Duration(seconds: 1),
            ),
          ).closed.then((_) => _stockWarningShown = false);
      }

      setState(() {}); // revert TextField
      return;
    }

    if (newQty <= 0) {
      _activeCheckout!.items.remove(entry);
    } else {
      entry.quantity = newQty;
    }

    _recalculateAndSaveCheckout();
  }

  void _addItem(Item item) {
    final items = _activeCheckout!.items;

    final existing = items.cast<CheckoutItem?>().firstWhere(
          (e) => e?.itemId == item.key,
          orElse: () => null,
        );

    if (item.isStockManaged && _quantityForItem(item) >= item.stockQuantity) {
      if (!_stockWarningShown) {
        _stockWarningShown = true;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                "Cannot add more than available stock (${item.stockQuantity})",
              ),
              duration: const Duration(seconds: 1),
            ),
          ).closed.then((_) => _stockWarningShown = false);
      }
      return;
    }

    if (existing != null) {
      existing.quantity += 1;
    } else {
      items.add(
        CheckoutItem()
          ..itemId = item.key as int
          ..itemName = item.name
          ..priceAtSale = item.price
          ..quantity = 1,
      );
    }

    _recalculateAndSaveCheckout();
  }

  void _removeItem(Item item) {
    final items = _activeCheckout!.items;

    final existing = items.cast<CheckoutItem?>().firstWhere(
          (e) => e?.itemId == item.key,
          orElse: () => null,
        );

    if (existing == null) return;

    if (existing.quantity > 1) {
      existing.quantity -= 1;
    } else {
      items.remove(existing);
    }

    _recalculateAndSaveCheckout();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Row(
        children: [
          Expanded(child: _buildItemListSection()),
          Container(width: 1, color: Colors.grey[300]),
          SizedBox(width: 450, child: _buildCartSummary()),
        ],
      ),
    );
  }

  Widget _buildItemListSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search items',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(child: _buildFilteredItemList()),
      ],
    );
  }

  Widget _buildFilteredItemList() {
    if (_filteredItems.isEmpty) {
      return const Center(child: Text("No items found."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final qty = _quantityForItem(item);

        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              "\$${item.price.toStringAsFixed(2)}"
              "${item.isStockManaged ? " · Stock: ${item.stockQuantity}" : ""}",
            ),
            trailing:
                Text(qty.toString(), style: const TextStyle(fontSize: 16)),
            onTap: () => _addItem(item),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary() {
    final items = _activeCheckout?.items ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Cart",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: items.isEmpty
                        ? Colors.grey[300]
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${items.length} ${items.length == 1 ? 'item' : 'items'}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: items.isEmpty
                          ? Colors.grey[700]
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    "Item",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 70,
                  child: Text(
                    "Qty",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  width: 80,
                  child: Text(
                    "Total",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Cart items list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "Your cart is empty",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add items to get started",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      final isSelected = _selectedCartItem == e;

                      return InkWell(
                        onTap: () => setState(() => _selectedCartItem = e),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3)
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$${e.priceAtSale.toStringAsFixed(2)} each",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                child: _CartQuantityEditor(
                                  item: e,
                                  onSubmitted: (qty) =>
                                      _setQuantityWithStockCheck(e, qty),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  "\$${(e.priceAtSale * e.quantity).toStringAsFixed(2)}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.grey[600],
                                onPressed: () {
                                  items.remove(e);
                                  _recalculateAndSaveCheckout();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom section with total and checkout button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Subtotal:",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      "\$${_total.toStringAsFixed(2)}",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${_total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (_isCartEmpty || _isProcessing)
                        ? null
                        : _completeCheckout,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment),
                              SizedBox(width: 8),
                              Text(
                                "Complete Checkout",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Complete Checkout ----------------

  Future<void> _completeCheckout() async {
    if (_isCartEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      for (final entry in _activeCheckout!.items) {
        final item = _itemBox.get(entry.itemId);
        if (item != null && item.isStockManaged) {
          item.stockQuantity -= entry.quantity;
          await item.save();
        }
      }

      _activeCheckout!
        ..status = 'completed'
        ..date = DateTime.now()
        ..totalAmount = _total;

      await _activeCheckout!.save();

      _activeCheckout = _createNewCheckout();
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout completed!")),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during checkout: $e")),
      );
    }
  }
}

class _CartQuantityEditor extends StatefulWidget {
  final CheckoutItem item;
  final void Function(int quantity) onSubmitted;

  const _CartQuantityEditor({
    required this.item,
    required this.onSubmitted,
  });

  @override
  State<_CartQuantityEditor> createState() => _CartQuantityEditorState();
}

class _CartQuantityEditorState extends State<_CartQuantityEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant _CartQuantityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = widget.item.quantity.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        onSubmitted: (value) {
          final qty = int.tryParse(value);
          if (qty != null) {
            widget.onSubmitted(qty);
          } else {
            _controller.text = widget.item.quantity.toString();
          }
        },
      ),
    );
  }
}
