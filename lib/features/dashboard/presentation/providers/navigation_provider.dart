import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum representing different sections of the app
enum DashboardSection {
  dashboard(0),
  checkout(1),
  items(2),
  bills(3);

  final int navIndex;
  const DashboardSection(this.navIndex);

  static DashboardSection fromIndex(int navIndex) {
    return DashboardSection.values.firstWhere(
      (section) => section.navIndex == navIndex,
      orElse: () => DashboardSection.dashboard,
    );
  }
}

/// Provider for managing navigation state
class NavigationNotifier extends StateNotifier<DashboardSection> {
  NavigationNotifier() : super(DashboardSection.dashboard);

  void navigateTo(DashboardSection section) {
    state = section;
  }

  void navigateToIndex(int navIndex) {
    state = DashboardSection.fromIndex(navIndex);
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, DashboardSection>((ref) {
  return NavigationNotifier();
});
