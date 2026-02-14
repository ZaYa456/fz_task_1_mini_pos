import 'package:fz_task_1/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:fz_task_1/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Use case for retrieving dashboard statistics
class GetDashboardStats {
  final DashboardRepository repository;

  GetDashboardStats(this.repository);

  /// Get current dashboard stats
  DashboardStats call() {
    return repository.getStats();
  }
}
