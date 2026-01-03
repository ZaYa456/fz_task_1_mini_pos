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

  final Map<Item, int> _cart = {};
  bool _isProcessing = false;
  bool _stockWarningShown = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<Item>(kItemBox);
    _checkoutBox = Hive.box<Checkout>(kCheckoutBox);

    _filteredItems = _itemBox.values.toList();

    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _itemBox.values
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    });
  }

  double get _total {
    double sum = 0;
    _cart.forEach((item, qty) => sum += item.price * qty);
    return sum;
  }

  bool get _isCartEmpty => !_cart.values.any((qty) => qty > 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Row(
        children: [
          Expanded(child: _buildItemListSection()),
          Container(width: 1, color: Colors.grey[300]),
          SizedBox(width: 300, child: _buildCartSummary(context)),
        ],
      ),
    );
  }

  // ---------------- Items List Section ----------------
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
        final qty = _cart[item] ?? 0;

        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              "\$${item.price.toStringAsFixed(2)}${item.isStockManaged ? " - Stock: ${item.stockQuantity}" : ""}",
            ),
            trailing: SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: qty > 0
                        ? () => setState(() => _cart[item] = qty - 1)
                        : null,
                  ),
                  Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final currentQty = _cart[item] ?? 0;

                      if (item.isStockManaged &&
                          currentQty >= item.stockQuantity) {
                        if (!_stockWarningShown) {
                          _stockWarningShown = true;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Cannot add more than available stock (${item.stockQuantity})"),
                                duration: const Duration(seconds: 1),
                              ),
                            ).closed.then((_) => _stockWarningShown = false);
                        }
                        return;
                      }

                      setState(() => _cart[item] = currentQty + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Cart Summary ----------------
  Widget _buildCartSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Cart",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _cart.entries
                  .where((e) => e.value > 0)
                  .map(
                    (e) => ListTile(
                      title: Text(e.key.name),
                      trailing: Text(
                          "${e.value} x \$${e.key.price.toStringAsFixed(2)}"),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("\$${_total.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
              label:
                  Text(_isProcessing ? "Processing..." : "Complete Checkout"),
              onPressed:
                  (_isCartEmpty || _isProcessing) ? null : _completeCheckout,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Complete Checkout ----------------
  void _completeCheckout() async {
    if (_isCartEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();

      final checkout = Checkout()
        ..id = DateTime.now().millisecondsSinceEpoch
        ..date = now
        ..totalAmount = _total
        ..items = _cart.entries
            .where((e) => e.value > 0)
            .map((e) => CheckoutItem()
              ..itemId = e.key.key as int
              ..itemName = e.key.name
              ..priceAtSale = e.key.price
              ..quantity = e.value)
            .toList();

      await _checkoutBox.add(checkout);

      // Deduct stock
      _cart.forEach((item, qty) {
        if (item.isStockManaged) {
          item.stockQuantity -= qty;
          item.save();
        }
      });

      setState(() {
        _cart.clear();
        _isProcessing = false;
      });

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
