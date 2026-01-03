import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/checkout_model.dart';
import '../services/hive_setup.dart';

enum SortOption { dateDesc, dateAsc, totalDesc, totalAsc }

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  late Box<Checkout> _checkoutBox;
  Checkout? _selectedBill;

  SortOption _currentSort = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _checkoutBox = Hive.box<Checkout>(kCheckoutBox);

    if (_checkoutBox.isNotEmpty) {
      _selectedBill = _checkoutBox.values.toList().last;
    }
  }

  List<Checkout> _getSortedBills() {
    final bills = _checkoutBox.values.toList();

    bills.sort((a, b) {
      switch (_currentSort) {
        case SortOption.dateAsc:
          return a.date.compareTo(b.date);
        case SortOption.dateDesc:
          return b.date.compareTo(a.date);
        case SortOption.totalAsc:
          return a.totalAmount.compareTo(b.totalAmount);
        case SortOption.totalDesc:
          return b.totalAmount.compareTo(a.totalAmount);
      }
    });

    return bills;
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.dateAsc:
        return "Date ↑";
      case SortOption.dateDesc:
        return "Date ↓";
      case SortOption.totalAsc:
        return "Total ↑";
      case SortOption.totalDesc:
        return "Total ↓";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bills"),
        actions: [
          // Sort Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<SortOption>(
              value: _currentSort,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox(),
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(_getSortLabel(option)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currentSort = value);
                }
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Checkout>>(
        valueListenable: _checkoutBox.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No bills found"));
          }

          final bills = _getSortedBills();

          return Row(
            children: [
              // Left: Bills List
              Expanded(
                flex: 2,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final isSelected = _selectedBill == bill;

                      return Card(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : null,
                        child: ListTile(
                          title: Text("Bill #${bill.id}"),
                          subtitle:
                              Text("${bill.date.toLocal()}".split('.')[0]),
                          trailing:
                              Text("\$${bill.totalAmount.toStringAsFixed(2)}"),
                          selected: isSelected,
                          onTap: () => setState(() => _selectedBill = bill),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Divider
              VerticalDivider(width: 1, color: Colors.grey[300]),

              // Right: Selected Bill Details
              Expanded(
                flex: 3,
                child: _selectedBill == null
                    ? const Center(child: Text("Select a bill to see details"))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bill #${_selectedBill!.id}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Date: ${_selectedBill!.date.toLocal()}"
                                .split('.')[0]),
                            const SizedBox(height: 16),
                            const Text(
                              "Items:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _selectedBill!.items.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _selectedBill!.items[index];
                                  return ListTile(
                                    title: Text(item.itemName),
                                    trailing: Text(
                                        "${item.quantity} x \$${item.priceAtSale.toStringAsFixed(2)}"),
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Total: \$${_selectedBill!.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
