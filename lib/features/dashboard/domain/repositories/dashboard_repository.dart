import 'package:fz_task_1/features/dashboard/domain/entities/dashboard_stats.dart';

/// Abstract repository for dashboard data
abstract class DashboardRepository {
  /// Get current dashboard statistics
  DashboardStats getStats();

  /// Stream of dashboard statistics for real-time updates
  Stream<DashboardStats> watchStats();
}
