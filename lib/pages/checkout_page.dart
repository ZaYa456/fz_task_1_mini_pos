// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// import '../services/hive_setup.dart';
// import '../models/item_model.dart';
// import '../models/checkout_model.dart';
// import '../models/checkout_items_model.dart';

// class CheckoutPage extends StatefulWidget {
//   const CheckoutPage({super.key});

//   @override
//   State<CheckoutPage> createState() => _CheckoutPageState();
// }

// class _CheckoutPageState extends State<CheckoutPage> {
//   late Box<Item> _itemBox;
//   late Box<Checkout> _checkoutBox;

//   Checkout? _activeCheckout;
//   CheckoutItem? _selectedCartItem;

//   bool _isProcessing = false;
//   bool _stockWarningShown = false;

//   // Search
//   final TextEditingController _searchController = TextEditingController();
//   List<Item> _filteredItems = [];

//   // ---------------- Lifecycle ----------------

//   @override
//   void initState() {
//     super.initState();
//     _itemBox = Hive.box<Item>(kItemBox);
//     _checkoutBox = Hive.box<Checkout>(kCheckoutBox);

//     _filteredItems = _itemBox.values.toList();
//     _searchController.addListener(_applySearch);

//     _loadOrCreateActiveCheckout();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // ---------------- Checkout Handling ----------------

//   void _loadOrCreateActiveCheckout() {
//     _activeCheckout = _checkoutBox.values.firstWhere(
//       (c) => c.status == 'open',
//       orElse: _createNewCheckout,
//     );
//   }

//   Checkout _createNewCheckout() {
//     final checkout = Checkout()
//       ..id = DateTime.now().millisecondsSinceEpoch
//       ..date = DateTime.now()
//       ..items = []
//       ..totalAmount = 0
//       ..status = 'open';

//     _checkoutBox.add(checkout);
//     return checkout;
//   }

//   void _recalculateAndSaveCheckout() {
//     if (_activeCheckout == null) return;

//     _activeCheckout!
//       ..totalAmount = _total
//       ..save();

//     setState(() {});
//   }

//   // ---------------- Search ----------------

//   void _applySearch() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredItems = _itemBox.values
//           .where((item) => item.name.toLowerCase().contains(query))
//           .toList();
//     });
//   }

//   // ---------------- Cart Helpers ----------------

//   double get _total {
//     return _activeCheckout?.items.fold(
//           0,
//           (sum, e) => sum! + e.priceAtSale * e.quantity,
//         ) ??
//         0;
//   }

//   bool get _isCartEmpty =>
//       _activeCheckout == null || _activeCheckout!.items.isEmpty;

//   int _quantityForItem(Item item) {
//     final entry = _activeCheckout!.items.cast<CheckoutItem?>().firstWhere(
//           (e) => e?.itemId == item.key,
//           orElse: () => null,
//         );
//     return entry?.quantity ?? 0;
//   }

//   // ---------------- Stock-aware quantity setter ----------------

//   void _setQuantityWithStockCheck(CheckoutItem entry, int newQty) {
//     final item = _itemBox.get(entry.itemId);

//     if (item == null) return;

//     if (item.isStockManaged && newQty > item.stockQuantity) {
//       if (!_stockWarningShown) {
//         _stockWarningShown = true;
//         ScaffoldMessenger.of(context)
//           ..hideCurrentSnackBar()
//           ..showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Only ${item.stockQuantity} in stock for ${item.name}",
//               ),
//               duration: const Duration(seconds: 1),
//             ),
//           ).closed.then((_) => _stockWarningShown = false);
//       }

//       setState(() {}); // revert TextField
//       return;
//     }

//     if (newQty <= 0) {
//       _activeCheckout!.items.remove(entry);
//     } else {
//       entry.quantity = newQty;
//     }

//     _recalculateAndSaveCheckout();
//   }

//   void _addItem(Item item) {
//     final items = _activeCheckout!.items;

//     final existing = items.cast<CheckoutItem?>().firstWhere(
//           (e) => e?.itemId == item.key,
//           orElse: () => null,
//         );

//     if (item.isStockManaged && _quantityForItem(item) >= item.stockQuantity) {
//       if (!_stockWarningShown) {
//         _stockWarningShown = true;
//         ScaffoldMessenger.of(context)
//           ..hideCurrentSnackBar()
//           ..showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Cannot add more than available stock (${item.stockQuantity})",
//               ),
//               duration: const Duration(seconds: 1),
//             ),
//           ).closed.then((_) => _stockWarningShown = false);
//       }
//       return;
//     }

//     if (existing != null) {
//       existing.quantity += 1;
//     } else {
//       items.add(
//         CheckoutItem()
//           ..itemId = item.key as int
//           ..itemName = item.name
//           ..priceAtSale = item.price
//           ..quantity = 1,
//       );
//     }

//     _recalculateAndSaveCheckout();
//   }

//   void _removeItem(Item item) {
//     final items = _activeCheckout!.items;

//     final existing = items.cast<CheckoutItem?>().firstWhere(
//           (e) => e?.itemId == item.key,
//           orElse: () => null,
//         );

//     if (existing == null) return;

//     if (existing.quantity > 1) {
//       existing.quantity -= 1;
//     } else {
//       items.remove(existing);
//     }

//     _recalculateAndSaveCheckout();
//   }

//   // ---------------- UI ----------------

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Checkout")),
//       body: Row(
//         children: [
//           Expanded(child: _buildItemListSection()),
//           Container(width: 1, color: Colors.grey[300]),
//           SizedBox(width: 450, child: _buildCartSummary()),
//         ],
//       ),
//     );
//   }

//   Widget _buildItemListSection() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: TextField(
//             controller: _searchController,
//             decoration: const InputDecoration(
//               labelText: 'Search items',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.search),
//             ),
//           ),
//         ),
//         Expanded(child: _buildFilteredItemList()),
//       ],
//     );
//   }

//   Widget _buildFilteredItemList() {
//     if (_filteredItems.isEmpty) {
//       return const Center(child: Text("No items found."));
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: _filteredItems.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (context, index) {
//         final item = _filteredItems[index];
//         final qty = _quantityForItem(item);

//         return Card(
//           child: ListTile(
//             title: Text(item.name),
//             subtitle: Text(
//               "\$${item.price.toStringAsFixed(2)}"
//               "${item.isStockManaged ? " · Stock: ${item.stockQuantity}" : ""}",
//             ),
//             trailing:
//                 Text(qty.toString(), style: const TextStyle(fontSize: 16)),
//             onTap: () => _addItem(item),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildCartSummary() {
//     final items = _activeCheckout?.items ?? [];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         border: Border(left: BorderSide(color: Colors.grey[200]!)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.shopping_cart, size: 24),
//                 const SizedBox(width: 12),
//                 const Text(
//                   "Cart",
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: items.isEmpty
//                         ? Colors.grey[300]
//                         : Theme.of(context)
//                             .colorScheme
//                             .primary
//                             .withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "${items.length} ${items.length == 1 ? 'item' : 'items'}",
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: items.isEmpty
//                           ? Colors.grey[700]
//                           : Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Column headers
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
//             ),
//             child: Row(
//               children: [
//                 const Expanded(
//                   flex: 3,
//                   child: Text(
//                     "Item",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   width: 70,
//                   child: Text(
//                     "Qty",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const SizedBox(
//                   width: 80,
//                   child: Text(
//                     "Total",
//                     textAlign: TextAlign.right,
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 48),
//               ],
//             ),
//           ),

//           // Cart items list
//           Expanded(
//             child: items.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.shopping_cart_outlined,
//                             size: 64, color: Colors.grey[300]),
//                         const SizedBox(height: 16),
//                         Text(
//                           "Your cart is empty",
//                           style:
//                               TextStyle(fontSize: 16, color: Colors.grey[600]),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           "Add items to get started",
//                           style:
//                               TextStyle(fontSize: 14, color: Colors.grey[400]),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     itemCount: items.length,
//                     itemBuilder: (context, index) {
//                       final e = items[index];
//                       final isSelected = _selectedCartItem == e;

//                       return InkWell(
//                         onTap: () => setState(() => _selectedCartItem = e),
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 4),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? Theme.of(context)
//                                     .colorScheme
//                                     .primary
//                                     .withOpacity(0.08)
//                                 : Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: isSelected
//                                   ? Theme.of(context)
//                                       .colorScheme
//                                       .primary
//                                       .withOpacity(0.3)
//                                   : Colors.grey[200]!,
//                               width: isSelected ? 2 : 1,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       e.itemName,
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         fontSize: 14,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       "\$${e.priceAtSale.toStringAsFixed(2)} each",
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               SizedBox(
//                                 width: 70,
//                                 child: _CartQuantityEditor(
//                                   item: e,
//                                   onSubmitted: (qty) =>
//                                       _setQuantityWithStockCheck(e, qty),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               SizedBox(
//                                 width: 80,
//                                 child: Text(
//                                   "\$${(e.priceAtSale * e.quantity).toStringAsFixed(2)}",
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.close, size: 20),
//                                 color: Colors.grey[600],
//                                 onPressed: () {
//                                   items.remove(e);
//                                   _recalculateAndSaveCheckout();
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),

//           // Bottom section with total and checkout button
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(top: BorderSide(color: Colors.grey[200]!)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Subtotal:",
//                       style: TextStyle(fontSize: 16, color: Colors.black87),
//                     ),
//                     Text(
//                       "\$${_total.toStringAsFixed(2)}",
//                       style:
//                           const TextStyle(fontSize: 16, color: Colors.black87),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         "Total:",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         "\$${_total.toStringAsFixed(2)}",
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onPressed: (_isCartEmpty || _isProcessing)
//                         ? null
//                         : _completeCheckout,
//                     child: _isProcessing
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2.5,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.payment),
//                               SizedBox(width: 8),
//                               Text(
//                                 "Complete Checkout",
//                                 style: TextStyle(
//                                     fontSize: 16, fontWeight: FontWeight.w600),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- Complete Checkout ----------------

//   Future<void> _completeCheckout() async {
//     if (_isCartEmpty || _isProcessing) return;

//     setState(() => _isProcessing = true);

//     try {
//       for (final entry in _activeCheckout!.items) {
//         final item = _itemBox.get(entry.itemId);
//         if (item != null && item.isStockManaged) {
//           item.stockQuantity -= entry.quantity;
//           await item.save();
//         }
//       }

//       _activeCheckout!
//         ..status = 'completed'
//         ..date = DateTime.now()
//         ..totalAmount = _total;

//       await _activeCheckout!.save();

//       _activeCheckout = _createNewCheckout();
//       setState(() => _isProcessing = false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Checkout completed!")),
//       );
//     } catch (e) {
//       setState(() => _isProcessing = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error during checkout: $e")),
//       );
//     }
//   }
// }

// class _CartQuantityEditor extends StatefulWidget {
//   final CheckoutItem item;
//   final void Function(int quantity) onSubmitted;

//   const _CartQuantityEditor({
//     required this.item,
//     required this.onSubmitted,
//   });

//   @override
//   State<_CartQuantityEditor> createState() => _CartQuantityEditorState();
// }

// class _CartQuantityEditorState extends State<_CartQuantityEditor> {
//   late final TextEditingController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController(text: widget.item.quantity.toString());
//   }

//   @override
//   void didUpdateWidget(covariant _CartQuantityEditor oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     _controller.text = widget.item.quantity.toString();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 40,
//       child: TextField(
//         controller: _controller,
//         textAlign: TextAlign.center,
//         keyboardType: TextInputType.number,
//         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         decoration: InputDecoration(
//           isDense: true,
//           contentPadding:
//               const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(color: Colors.grey[300]!),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(color: Colors.grey[300]!),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(
//                 color: Theme.of(context).colorScheme.primary, width: 2),
//           ),
//         ),
//         onSubmitted: (value) {
//           final qty = int.tryParse(value);
//           if (qty != null) {
//             widget.onSubmitted(qty);
//           } else {
//             _controller.text = widget.item.quantity.toString();
//           }
//         },
//       ),
//     );
//   }
// }

// /////////////////////////////////////////////////////////////////////////////
// Improved with Claude
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_setup.dart';
import '../features/items/models/item_model.dart';
import '../features/checkout/models/checkout_model.dart';
import '../features/checkout/models/checkout_items_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Box<Item> _itemBox;
  late Box<Checkout> _checkoutBox;

  Checkout? _activeCheckout;
  int? _selectedCartItemIndex;

  bool _isProcessing = false;
  bool _stockWarningShown = false;

  // Search & Barcode
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Item> _filteredItems = [];
  
  // Quick categories
  String? _selectedCategory;
  
  // Hold transactions
  final List<Checkout> _heldCheckouts = [];

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<Item>(kItemBox);
    _checkoutBox = Hive.box<Checkout>(kCheckoutBox);

    _filteredItems = _itemBox.values.toList();
    _searchController.addListener(_applySearch);

    _loadOrCreateActiveCheckout();
    _loadHeldCheckouts();
    
    // Auto-focus search for barcode scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ---------------- Checkout Handling ----------------

  void _loadOrCreateActiveCheckout() {
    _activeCheckout = _checkoutBox.values.firstWhere(
      (c) => c.status == 'open',
      orElse: _createNewCheckout,
    );
  }
  
  void _loadHeldCheckouts() {
    _heldCheckouts.clear();
    _heldCheckouts.addAll(
      _checkoutBox.values.where((c) => c.status == 'held'),
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

  // ---------------- Search & Barcode ----------------

  void _applySearch() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _selectedCategory == null
            ? _itemBox.values.toList()
            : _itemBox.values
                .where((item) => item.category == _selectedCategory)
                .toList();
      });
      return;
    }

    // Try exact barcode match first
    final barcodeMatch = _itemBox.values.cast<Item?>().firstWhere(
      (item) => item?.barcode?.toLowerCase() == query,
      orElse: () => null,
    );

    if (barcodeMatch != null) {
      _addItem(barcodeMatch);
      _searchController.clear();
      _searchFocusNode.requestFocus();
      return;
    }

    // Otherwise, filter by name
    setState(() {
      _filteredItems = _itemBox.values
          .where((item) =>
              item.name.toLowerCase().contains(query) &&
              (_selectedCategory == null || item.category == _selectedCategory))
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
  
  double get _tax => _total * 0.0; // Configure tax rate as needed
  
  double get _grandTotal => _total + _tax;

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
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          ).closed.then((_) => _stockWarningShown = false);
      }
      return;
    }

    if (newQty <= 0) {
      _activeCheckout!.items.remove(entry);
      if (_selectedCartItemIndex != null &&
          _selectedCartItemIndex! >= _activeCheckout!.items.length) {
        _selectedCartItemIndex = _activeCheckout!.items.isEmpty
            ? null
            : _activeCheckout!.items.length - 1;
      }
    } else {
      entry.quantity = newQty;
    }

    _recalculateAndSaveCheckout();
  }

  void _addItem(Item item) {
    final items = _activeCheckout!.items;

    final existingIndex = items.indexWhere((e) => e.itemId == item.key);

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
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          ).closed.then((_) => _stockWarningShown = false);
      }
      return;
    }

    if (existingIndex != -1) {
      items[existingIndex].quantity += 1;
      setState(() => _selectedCartItemIndex = existingIndex);
    } else {
      items.add(
        CheckoutItem()
          ..itemId = item.key as int
          ..itemName = item.name
          ..priceAtSale = item.price
          ..quantity = 1,
      );
      setState(() => _selectedCartItemIndex = items.length - 1);
    }

    _recalculateAndSaveCheckout();
  }

  void _removeItem(Item item) {
    final items = _activeCheckout!.items;

    final existingIndex = items.indexWhere((e) => e.itemId == item.key);

    if (existingIndex == -1) return;

    if (items[existingIndex].quantity > 1) {
      items[existingIndex].quantity -= 1;
    } else {
      items.removeAt(existingIndex);
      if (_selectedCartItemIndex == existingIndex) {
        _selectedCartItemIndex = items.isEmpty ? null : 0;
      } else if (_selectedCartItemIndex != null &&
          _selectedCartItemIndex! > existingIndex) {
        _selectedCartItemIndex = _selectedCartItemIndex! - 1;
      }
    }

    _recalculateAndSaveCheckout();
  }
  
  // ---------------- Keyboard Shortcuts ----------------
  
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    // F1 - Hold transaction
    if (event.logicalKey == LogicalKeyboardKey.f1) {
      _holdTransaction();
    }
    // F2 - Recall held transaction
    else if (event.logicalKey == LogicalKeyboardKey.f2) {
      _showHeldTransactions();
    }
    // F9 - Clear cart
    else if (event.logicalKey == LogicalKeyboardKey.f9) {
      _clearCart();
    }
    // F12 - Complete checkout (if cart not empty)
    else if (event.logicalKey == LogicalKeyboardKey.f12 && !_isCartEmpty) {
      _showPaymentDialog();
    }
    // Delete - Remove selected item
    else if (event.logicalKey == LogicalKeyboardKey.delete &&
        _selectedCartItemIndex != null) {
      final item = _activeCheckout!.items[_selectedCartItemIndex!];
      _activeCheckout!.items.removeAt(_selectedCartItemIndex!);
      _selectedCartItemIndex = null;
      _recalculateAndSaveCheckout();
    }
    // Arrow Up/Down - Navigate cart
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        _selectedCartItemIndex != null &&
        _selectedCartItemIndex! > 0) {
      setState(() => _selectedCartItemIndex = _selectedCartItemIndex! - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        _selectedCartItemIndex != null &&
        _selectedCartItemIndex! < _activeCheckout!.items.length - 1) {
      setState(() => _selectedCartItemIndex = _selectedCartItemIndex! + 1);
    }
    // Plus/Minus - Adjust quantity of selected item
    else if (event.logicalKey == LogicalKeyboardKey.add &&
        _selectedCartItemIndex != null) {
      final item = _activeCheckout!.items[_selectedCartItemIndex!];
      _setQuantityWithStockCheck(item, item.quantity + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.minus &&
        _selectedCartItemIndex != null) {
      final item = _activeCheckout!.items[_selectedCartItemIndex!];
      _setQuantityWithStockCheck(item, item.quantity - 1);
    }
  }

  // ---------------- Transaction Management ----------------
  
  void _holdTransaction() {
    if (_isCartEmpty) return;
    
    _activeCheckout!.status = 'held';
    _activeCheckout!.save();
    
    _heldCheckouts.add(_activeCheckout!);
    _activeCheckout = _createNewCheckout();
    _selectedCartItemIndex = null;
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transaction held"),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _showHeldTransactions() {
    if (_heldCheckouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No held transactions")),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Held Transactions"),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _heldCheckouts.length,
            itemBuilder: (context, index) {
              final checkout = _heldCheckouts[index];
              return ListTile(
                title: Text(
                  "${checkout.items.length} items - \$${checkout.totalAmount.toStringAsFixed(2)}",
                ),
                subtitle: Text(
                  "Held at ${TimeOfDay.fromDateTime(checkout.date).format(context)}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    checkout.delete();
                    _heldCheckouts.removeAt(index);
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
                onTap: () {
                  _recallHeldTransaction(index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
  
  void _recallHeldTransaction(int index) {
    // Save current if not empty
    if (!_isCartEmpty) {
      _activeCheckout!.status = 'held';
      _activeCheckout!.save();
      _heldCheckouts.add(_activeCheckout!);
    } else {
      _activeCheckout!.delete();
    }
    
    // Restore held transaction
    _activeCheckout = _heldCheckouts.removeAt(index);
    _activeCheckout!.status = 'open';
    _activeCheckout!.save();
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transaction recalled"),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _clearCart() {
    if (_isCartEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text("Are you sure you want to clear all items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _activeCheckout!.items.clear();
              _selectedCartItemIndex = null;
              _recalculateAndSaveCheckout();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Checkout"),
          actions: [
            // Held transactions indicator
            if (_heldCheckouts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Badge(
                    label: Text(_heldCheckouts.length.toString()),
                    child: IconButton(
                      icon: const Icon(Icons.pause_circle_outline),
                      onPressed: _showHeldTransactions,
                      tooltip: "Held Transactions (F2)",
                    ),
                  ),
                ),
              ),
            // Quick actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'hold':
                    _holdTransaction();
                    break;
                  case 'recall':
                    _showHeldTransactions();
                    break;
                  case 'clear':
                    _clearCart();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'hold',
                  child: Row(
                    children: [
                      Icon(Icons.pause),
                      SizedBox(width: 8),
                      Text("Hold (F1)"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recall',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text("Recall (F2)"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Clear Cart (F9)"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(child: _buildItemListSection()),
            Container(width: 1, color: Colors.grey[300]),
            SizedBox(width: 450, child: _buildCartSummary()),
          ],
        ),
      ),
    );
  }

  Widget _buildItemListSection() {
    // Get unique categories
    final categories = _itemBox.values
        .map((item) => item.category)
        .where((cat) => cat != null && cat.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      children: [
        // Search bar with barcode support
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              labelText: 'Search or scan barcode',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.requestFocus();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _searchFocusNode.requestFocus(),
          ),
        ),
        
        // Category filters
        if (categories.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text("All"),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                        _applySearch();
                      });
                    },
                  ),
                ),
                ...categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category!),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                            _applySearch();
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        
        const Divider(height: 1),
        Expanded(child: _buildFilteredItemList()),
      ],
    );
  }

  Widget _buildFilteredItemList() {
    if (_filteredItems.isEmpty) {
      return const Center(child: Text("No items found."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final qty = _quantityForItem(item);
        final isLowStock =
            item.isStockManaged && item.stockQuantity <= 5 && item.stockQuantity > 0;
        final isOutOfStock = item.isStockManaged && item.stockQuantity <= 0;

        return Card(
          elevation: qty > 0 ? 4 : 1,
          color: isOutOfStock
              ? Colors.grey[200]
              : qty > 0
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
          child: InkWell(
            onTap: isOutOfStock ? null : () => _addItem(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isOutOfStock ? Colors.grey : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    "\$${item.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Stock info
                  if (item.isStockManaged)
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12,
                          color: isOutOfStock
                              ? Colors.red
                              : isLowStock
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOutOfStock
                              ? "Out of stock"
                              : "${item.stockQuantity}",
                          style: TextStyle(
                            fontSize: 11,
                            color: isOutOfStock
                                ? Colors.red
                                : isLowStock
                                    ? Colors.orange
                                    : Colors.grey[600],
                            fontWeight: isLowStock || isOutOfStock
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ],
                    ),
                  
                  // In cart indicator
                  if (qty > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "×$qty in cart",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            child: const Row(
              children: [
                Expanded(
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
                SizedBox(
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
                SizedBox(width: 12),
                SizedBox(
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
                SizedBox(width: 48),
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
                          "Scan or add items to get started",
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
                      final isSelected = _selectedCartItemIndex == index;

                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedCartItemIndex = index),
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
                              
                              // Quick increment/decrement buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        size: 20),
                                    onPressed: () =>
                                        _setQuantityWithStockCheck(
                                            e, e.quantity - 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      e.quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 20),
                                    onPressed: () =>
                                        _setQuantityWithStockCheck(
                                            e, e.quantity + 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
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
                                  items.removeAt(index);
                                  if (_selectedCartItemIndex == index) {
                                    _selectedCartItemIndex = null;
                                  }
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
                
                if (_tax > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tax:",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        "\$${_tax.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
                
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
                        "\$${_grandTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        onPressed: _isCartEmpty ? null : _holdTransaction,
                        icon: const Icon(Icons.pause, size: 20),
                        label: const Text("Hold"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: (_isCartEmpty || _isProcessing)
                            ? null
                            : _showPaymentDialog,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.payment, size: 20),
                        label: const Text(
                          "Pay",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Keyboard shortcuts hint
                const SizedBox(height: 12),
                Text(
                  "F1:Hold • F2:Recall • F9:Clear • F12:Pay",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Payment Dialog ----------------

  void _showPaymentDialog() {
    String paymentMethod = 'cash';
    final amountController = TextEditingController(
      text: _grandTotal.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final amountPaid = double.tryParse(amountController.text) ?? 0;
            final change = amountPaid - _grandTotal;
            
            return AlertDialog(
              title: const Text("Payment"),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total due
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
                            "Total Due:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "\$${_grandTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment method
                    const Text(
                      "Payment Method:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text("Cash"),
                          selected: paymentMethod == 'cash',
                          onSelected: (selected) {
                            setDialogState(() {
                              paymentMethod = 'cash';
                              amountController.text =
                                  _grandTotal.toStringAsFixed(2);
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Card"),
                          selected: paymentMethod == 'card',
                          onSelected: (selected) {
                            setDialogState(() {
                              paymentMethod = 'card';
                              amountController.text =
                                  _grandTotal.toStringAsFixed(2);
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Other"),
                          selected: paymentMethod == 'other',
                          onSelected: (selected) {
                            setDialogState(() {
                              paymentMethod = 'other';
                              amountController.text =
                                  _grandTotal.toStringAsFixed(2);
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Amount received (only for cash)
                    if (paymentMethod == 'cash') ...[
                      const Text(
                        "Amount Received:",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      
                      // Quick amount buttons
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [20, 50, 100].map((amount) {
                          return OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                amountController.text = amount.toString();
                              });
                            },
                            child: Text("\$$amount"),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Change
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: change >= 0
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: change >= 0
                                ? Colors.green[200]!
                                : Colors.red[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              change >= 0 ? "Change:" : "Short:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: change >= 0
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                            Text(
                              "\$${change.abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: change >= 0
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: (paymentMethod == 'cash' && change < 0) ||
                          _isProcessing
                      ? null
                      : () {
                          Navigator.pop(context);
                          _completeCheckout(paymentMethod, amountPaid);
                        },
                  child: const Text("Complete Payment"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- Complete Checkout ----------------

  Future<void> _completeCheckout(String paymentMethod, double amountPaid) async {
    if (_isCartEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Update stock
      for (final entry in _activeCheckout!.items) {
        final item = _itemBox.get(entry.itemId);
        if (item != null && item.isStockManaged) {
          item.stockQuantity -= entry.quantity;
          await item.save();
        }
      }

      // Complete checkout
      _activeCheckout!
        ..status = 'completed'
        ..date = DateTime.now()
        ..totalAmount = _grandTotal;

      await _activeCheckout!.save();

      // Create new active checkout
      final completedCheckout = _activeCheckout;
      _activeCheckout = _createNewCheckout();
      _selectedCartItemIndex = null;
      
      setState(() => _isProcessing = false);

      // Show success and offer receipt
      if (mounted) {
        final shouldPrintReceipt = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text("Payment Complete"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total: \$${_grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16),
                ),
                if (paymentMethod == 'cash') ...[
                  Text(
                    "Paid: \$${amountPaid.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Change: \$${(amountPaid - _grandTotal).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text("Would you like to print a receipt?"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Print Receipt"),
              ),
            ],
          ),
        );

        if (shouldPrintReceipt == true && completedCheckout != null) {
          _printReceipt(completedCheckout, paymentMethod, amountPaid);
        }
      }
      
      // Refocus search for next transaction
      _searchFocusNode.requestFocus();
      
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error during checkout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _printReceipt(Checkout checkout, String paymentMethod, double amountPaid) {
    // TODO: Implement actual receipt printing
    // For now, show a preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Receipt"),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Text(
                    "YOUR STORE NAME",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(child: Text("123 Main St")),
                const Center(child: Text("City, State 12345")),
                const Divider(height: 24),
                Text(
                  "Date: ${checkout.date.toString().substring(0, 16)}",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "Transaction #${checkout.id}",
                  style: const TextStyle(fontSize: 12),
                ),
                const Divider(height: 24),
                ...checkout.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item.itemName} x${item.quantity}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            "\$${(item.priceAtSale * item.quantity).toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("\$${checkout.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (paymentMethod == 'cash') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Cash:"),
                      Text("\$${amountPaid.toStringAsFixed(2)}"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Change:"),
                      Text(
                          "\$${(amountPaid - checkout.totalAmount).toStringAsFixed(2)}"),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Payment: ${paymentMethod.toUpperCase()}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: Text("Thank you for your business!")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}