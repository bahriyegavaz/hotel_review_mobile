import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/api_dashboard_repository.dart';
import '../data/fake_dashboard_repository.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

/// Backend hazır olduğunda defaultValue'yu false yap.
/// Ya da: flutter run --dart-define=USE_FAKE_DASHBOARD=false
const bool useFakeDashboard = bool.fromEnvironment(
  'USE_FAKE_DASHBOARD',
  defaultValue: true,
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (useFakeDashboard) {
    return FakeDashboardRepository();
  }
  return ApiDashboardRepository(ref.watch(dioProvider));
});

/// Özet verileri yükler. Pull-to-refresh ile yenilenebilir.
class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() =>
      ref.read(dashboardRepositoryProvider).getSummary();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      ref.read(dashboardRepositoryProvider).getSummary,
    );
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
  DashboardController.new,
);