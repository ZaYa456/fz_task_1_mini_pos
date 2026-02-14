import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/auth/presentation/pages/login_page.dart';
import 'package:fz_task_1/features/bills/presentation/pages/bills_page.dart';
import 'package:fz_task_1/features/checkout/presentation/pages/checkout_page.dart';
import 'package:fz_task_1/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:fz_task_1/features/dashboard/presentation/widgets/app_navigation_rail.dart';
import 'package:fz_task_1/features/dashboard/presentation/widgets/dashboard_view.dart';
import 'package:fz_task_1/features/items/presentation/pages/items_page.dart';

/// Main home page with navigation and layout
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSection = ref.watch(navigationProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: Row(
        children: [
          const AppNavigationRail(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _getPageForSection(currentSection),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('POS Dashboard'),
      actions: [
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context, ref),
        ),
      ],
    );
  }

  Widget _getPageForSection(DashboardSection section) {
    switch (section) {
      case DashboardSection.dashboard:
        return const DashboardView();
      case DashboardSection.checkout:
        return const CheckoutPage();
      case DashboardSection.items:
        return const ItemsPage();
      case DashboardSection.bills:
        return const BillsPage();
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Perform logout
    await ref.read(authNotifierProvider.notifier).logout();

    if (!context.mounted) return;

    // Navigate to login page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
