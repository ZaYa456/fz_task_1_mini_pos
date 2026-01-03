import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'items_page.dart';
import 'checkout_page.dart';
import 'bills_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
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
      body: Center(
        child: _buildMenu(context),
      ),
    );
  }

  // ---------- Home Menu ----------

  Widget _buildMenu(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.point_of_sale,
          size: 80,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildMenuButton(
              context,
              icon: Icons.inventory_2_outlined,
              label: "Manage Items",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemsPage()),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.shopping_cart_checkout_outlined,
              label: "Checkout",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutPage()),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.receipt_long_outlined,
              label: "Bills",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BillsPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: 180,
      height: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
