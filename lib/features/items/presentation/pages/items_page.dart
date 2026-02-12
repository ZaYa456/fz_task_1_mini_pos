import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/items/domain/entities/item.dart';
import 'package:fz_task_1/features/items/presentation/providers/items_notifier.dart';
import 'package:fz_task_1/features/items/presentation/widgets/item_dialog.dart';
import 'package:fz_task_1/features/items/presentation/widgets/item_delete_confirmation_dialog.dart';

class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state
    final state = ref.watch(itemsNotifierProvider);
    final notifier = ref.read(itemsNotifierProvider.notifier);

    // Filtered & sorted items
    final items = notifier.filteredItems;

    String getSortLabel() {
      final fieldLabel = state.sortField == 'name' ? "Name" : "Price";
      final arrow = state.ascending ? "↑" : "↓";
      return "$fieldLabel $arrow";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Management"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                getSortLabel(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort items',
            onSelected: (value) {
              switch (value) {
                case "name_asc":
                  notifier.setSort("name", true);
                  break;
                case "name_desc":
                  notifier.setSort("name", false);
                  break;
                case "price_asc":
                  notifier.setSort("price", true);
                  break;
                case "price_desc":
                  notifier.setSort("price", false);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "name_asc", child: Text("Name ↑")),
              PopupMenuItem(value: "name_desc", child: Text("Name ↓")),
              PopupMenuItem(value: "price_asc", child: Text("Price ↑")),
              PopupMenuItem(value: "price_desc", child: Text("Price ↓")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add New Item",
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ItemDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: notifier.setSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search items...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Items list
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("No items found."))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            "\$${item.price.toStringAsFixed(2)}"
                            "${item.isStockManaged ? " - Stock: ${item.stockQuantity}" : ""}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => ItemDialog(item: item),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _confirmDelete(context, item, notifier),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Item item, ItemsNotifier notifier) async {
    final usage = await notifier.getItemUsage(item);

    final confirmed = await ItemDeleteConfirmationDialog.show(
      context,
      item,
      usage,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await notifier.deleteItem(item);

      final isUsed = usage['isUsed'] as bool;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUsed
                  ? '"${item.name}" deleted and removed from all carts'
                  : '"${item.name}" deleted successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
