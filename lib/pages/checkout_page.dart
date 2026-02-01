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
      orElse: () => _createNewCheckout(),
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
    if (_activeCheckout == null) return 0;
    return _activeCheckout!.items.fold(
      0,
      (sum, e) => sum + e.priceAtSale * e.quantity,
    );
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

    _activeCheckout!
      ..totalAmount = _total
      ..save();

    setState(() {});
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

    _activeCheckout!
      ..totalAmount = _total
      ..save();

    setState(() {});
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
          SizedBox(width: 300, child: _buildCartSummary()),
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
              "${item.isStockManaged ? " - Stock: ${item.stockQuantity}" : ""}",
            ),
            trailing: SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: qty > 0 ? () => _removeItem(item) : null,
                  ),
                  Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addItem(item),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary() {
    final items = _activeCheckout?.items ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Cart",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: items
                  .map(
                    (e) => ListTile(
                      title: Text(e.itemName),
                      trailing: Text(
                        "${e.quantity} x \$${e.priceAtSale.toStringAsFixed(2)}",
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "\$${_total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _isProcessing ? "Processing..." : "Complete Checkout",
              ),
              onPressed:
                  (_isCartEmpty || _isProcessing) ? null : _completeCheckout,
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
      // Deduct stock
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Checkout completed!")),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during checkout: $e")),
        );
      }
    }
  }
}
