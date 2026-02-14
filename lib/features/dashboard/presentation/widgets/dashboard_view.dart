import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/app/di.dart';
import 'package:fz_task_1/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:fz_task_1/features/dashboard/presentation/widgets/stat_card.dart';

/// Main dashboard view showing statistics and quick actions
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),
        _buildStatsSection(context, stats),
        const SizedBox(height: 32),
        _buildQuickActions(context, ref),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Overview of your POS system',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, stats) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        StatCard(
          title: 'Total Items',
          value: stats.itemCount.toString(),
          icon: Icons.inventory_2_outlined,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Total Bills',
          value: stats.billCount.toString(),
          icon: Icons.receipt_long_outlined,
          color: Colors.green,
        ),
        StatCard(
          title: 'Total Sales',
          value: '\$${stats.totalSales.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionButton(
              icon: Icons.shopping_cart_checkout,
              label: 'New Checkout',
              onPressed: () {
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo(DashboardSection.checkout);
              },
            ),
            _QuickActionButton(
              icon: Icons.add_box_outlined,
              label: 'Add Item',
              onPressed: () {
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo(DashboardSection.items);
              },
            ),
            _QuickActionButton(
              icon: Icons.receipt_outlined,
              label: 'View Bills',
              onPressed: () {
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo(DashboardSection.bills);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
