import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../providers/items_provider.dart';

class ItemDialog extends ConsumerStatefulWidget {
  final Item? item;

  const ItemDialog({this.item, super.key});

  @override
  ConsumerState<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends ConsumerState<ItemDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  bool isStockManaged = true;
  final formKey = GlobalKey<FormState>();

  bool get isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.name ?? '');
    priceController =
        TextEditingController(text: widget.item?.price.toString() ?? '');
    stockController = TextEditingController(
        text: widget.item?.stockQuantity.toString() ?? '0');
    isStockManaged = widget.item?.isStockManaged ?? true;
  }

  // FIX #1: Dispose controllers to prevent memory leaks
  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isNew ? "Add Item" : "Edit Item"),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
              validator: (v) => (v == null || v.isEmpty) ? "Enter name" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceController,
              // FIX #5: Ensure decimal options are explicit
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Price"),
              validator: (v) {
                if (v == null || v.isEmpty) return "Enter price";
                final p = double.tryParse(v);
                if (p == null || p <= 0) return "Enter valid price";
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Stock Managed"),
              value: isStockManaged,
              onChanged: (v) => setState(() => isStockManaged = v),
            ),
            if (isStockManaged)
              TextFormField(
                controller: stockController,
                // FIX #5: specific input type for integers
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                decoration: const InputDecoration(labelText: "Stock Quantity"),
                validator: (v) {
                  if (!isStockManaged) return null;
                  if (v == null || v.isEmpty) return "Enter stock quantity";
                  final q = int.tryParse(v);
                  if (q == null || q < 0) return "Quantity must be >= 0";
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text(isNew ? "Add" : "Save"),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;

            final notifier = ref.read(itemsProvider.notifier);

            if (isNew) {
              final newItem = Item()
                ..name = nameController.text.trim()
                ..price = double.parse(priceController.text.trim())
                ..isStockManaged = isStockManaged
                ..stockQuantity =
                    isStockManaged ? int.parse(stockController.text.trim()) : 0
                ..registeredDate = DateTime.now();

              await notifier.addItem(newItem);
            } else {
              // Edit existing: Modify the original object directly
              final itemToUpdate = widget.item!;
              itemToUpdate.name = nameController.text.trim();
              itemToUpdate.price = double.parse(priceController.text.trim());
              itemToUpdate.isStockManaged = isStockManaged;
              itemToUpdate.stockQuantity =
                  isStockManaged ? int.parse(stockController.text.trim()) : 0;
              // registeredDate remains untouched automatically

              await notifier.updateItem(itemToUpdate);
            }

            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
