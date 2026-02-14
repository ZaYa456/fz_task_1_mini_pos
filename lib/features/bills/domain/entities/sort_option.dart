/// Enum representing different sorting options for bills
enum BillsSortOption {
  dateDescending,
  dateAscending,
  totalDescending,
  totalAscending;

  /// Get display label for the sort option
  String get label {
    switch (this) {
      case BillsSortOption.dateAscending:
        return 'Date ↑';
      case BillsSortOption.dateDescending:
        return 'Date ↓';
      case BillsSortOption.totalAscending:
        return 'Total ↑';
      case BillsSortOption.totalDescending:
        return 'Total ↓';
    }
  }
}
