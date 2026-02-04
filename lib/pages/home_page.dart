import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/auth_service.dart';
import '../services/hive_setup.dart';
import '../features/checkout/models/checkout_model.dart';
import '../features/items/models/item_model.dart';

import 'login_page.dart';
import '../features/checkout/checkout_page.dart';
import '../features/items/items_page.dart';
import 'bills_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final authService = AuthService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardView(
        onNewCheckout: () {
          setState(() => _selectedIndex = 1); // Checkout
        },
      ),
      const CheckoutPage(),
      const ItemsPage(),
      const BillsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: Text('Checkout'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Items'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Bills'),
        ),
      ],
    );
  }
}

class DashboardView extends StatelessWidget {
  final VoidCallback onNewCheckout;

  const DashboardView({
    super.key,
    required this.onNewCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final itemBox = Hive.box<Item>(kItemBox);
    final checkoutBox = Hive.box<Checkout>(kCheckoutBox);

    final int itemCount = itemBox.length;
    final int billCount = checkoutBox.length;

    final double totalSales = checkoutBox.values.fold(
      0.0,
      (sum, bill) => sum + bill.totalAmount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              title: 'Total Sales',
              value: '\$${totalSales.toStringAsFixed(2)}',
              icon: Icons.attach_money,
            ),
            _StatCard(
              title: 'Bills',
              value: billCount.toString(),
              icon: Icons.receipt_long,
            ),
            _StatCard(
              title: 'Items',
              value: itemCount.toString(),
              icon: Icons.inventory_2,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('New Checkout'),
          onPressed: onNewCheckout,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
