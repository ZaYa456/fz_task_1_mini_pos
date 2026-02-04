import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_setup.dart';
import '../features/items/models/item_model.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late Box<Item> _itemBox;

  String _searchQuery = "";
  String _sortField = "name"; // or "price"
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<Item>(kItemBox);
  }

  String _getSortLabel() {
    String field = _sortField == "name" ? "Name" : "Price";
    String arrow = _ascending ? "↑" : "↓";
    return "$field $arrow";
  }

  List<Item> get _filteredItems {
    final items = _itemBox.values.toList();

    // 1. Filter by search query
    final filtered = items.where(
        (item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()));

    // 2. Sort
    final sorted = filtered.toList()
      ..sort((a, b) {
        int cmp;
        if (_sortField == "name") {
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else {
          cmp = a.price.compareTo(b.price);
        }
        return _ascending ? cmp : -cmp;
      });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Management"),
        actions: [
          // Show current sort option as a tooltip
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _getSortLabel(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort items',
            onSelected: (value) {
              setState(() {
                if (value == "name_asc") {
                  _sortField = "name";
                  _ascending = true;
                } else if (value == "name_desc") {
                  _sortField = "name";
                  _ascending = false;
                } else if (value == "price_asc") {
                  _sortField = "price";
                  _ascending = true;
                } else if (value == "price_desc") {
                  _sortField = "price";
                  _ascending = false;
                }
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "name_asc", child: Text("Name ↑")),
              PopupMenuItem(value: "name_desc", child: Text("Name ↓")),
              PopupMenuItem(value: "price_asc", child: Text("Price ↑")),
              PopupMenuItem(value: "price_desc", child: Text("Price ↓")),
            ],
          ),
          // Add new item button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add New Item",
            onPressed: () => _showItemDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search items...",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Item list
          Expanded(
            child: ValueListenableBuilder<Box<Item>>(
              valueListenable: _itemBox.listenable(),
              builder: (context, box, _) {
                final items = _filteredItems;

                if (items.isEmpty) {
                  return const Center(child: Text("No items found."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          "\$${item.price.toStringAsFixed(2)}${item.isStockManaged ? " - Stock: ${item.stockQuantity}" : ""}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showItemDialog(
                                  item: item,
                                  index: box.values.toList().indexOf(item)),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                final idx = box.values.toList().indexOf(item);
                                _deleteItem(idx);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- CRUD METHODS -----------------

  void _deleteItem(int index) {
    _itemBox.deleteAt(index);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item deleted.")),
    );
  }

  Future<void> _showItemDialog({Item? item, int? index}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: item?.stockQuantity.toString() ?? '0');

    bool isStockManaged = item?.isStockManaged ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? "Add Item" : "Edit Item"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Item Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter item name" : null,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Enter price";
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return "Enter valid price > 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stock Managed Switch
                SwitchListTile(
                  title: const Text("Stock Managed"),
                  value: isStockManaged,
                  onChanged: (value) => setState(() => isStockManaged = value),
                ),

                // Stock Quantity (shown only if isStockManaged is true)
                if (isStockManaged) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Stock Quantity",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!isStockManaged) return null;
                      if (value == null || value.isEmpty) {
                        return "Enter stock quantity";
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty < 0) {
                        return "Quantity must be >= 0";
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text(item == null ? "Add" : "Save"),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final name = nameController.text.trim();
                final price = double.parse(priceController.text.trim());
                final stockQty =
                    isStockManaged ? int.parse(stockController.text.trim()) : 0;

                if (item == null) {
                  // Add new item
                  _itemBox.add(Item()
                    ..name = name
                    ..price = price
                    ..isStockManaged = isStockManaged
                    ..stockQuantity = stockQty
                    ..registeredDate = DateTime.now());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Item added.")),
                  );
                } else {
                  // Edit existing
                  final updatedItem = item
                    ..name = name
                    ..price = price
                    ..isStockManaged = isStockManaged
                    ..stockQuantity = stockQty;
                  _itemBox.putAt(index!, updatedItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Item updated.")),
                  );
                }

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
