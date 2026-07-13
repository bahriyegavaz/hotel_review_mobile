import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

/// Backend hazır olmadan dashboard kartlarını geliştirmek için.
///
/// Varsayılan değerler rapordaki örnek çıktıya yakın seçildi:
/// 12/50 = %24 negatif oran -> eşik (%20) üstünde, uyarı rozetini test edebiliriz.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.summary});

  /// Testlerde farklı senaryolar denemek için dışarıdan verilebilir.
  final DashboardSummary? summary;

  @override
  Future<DashboardSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return summary ??
        const DashboardSummary(
          todayReviewCount: 7,
          openActionCount: 3,
          negativeReviewCount: 12,
          totalReviewCount: 50,
          averageRating: 4.1,
        );
  }
}