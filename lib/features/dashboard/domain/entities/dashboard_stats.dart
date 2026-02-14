/// Domain entity representing dashboard statistics
class DashboardStats {
  final int itemCount;
  final int billCount;
  final double totalSales;

  const DashboardStats({
    required this.itemCount,
    required this.billCount,
    required this.totalSales,
  });

  DashboardStats copyWith({
    int? itemCount,
    int? billCount,
    double? totalSales,
  }) {
    return DashboardStats(
      itemCount: itemCount ?? this.itemCount,
      billCount: billCount ?? this.billCount,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}
