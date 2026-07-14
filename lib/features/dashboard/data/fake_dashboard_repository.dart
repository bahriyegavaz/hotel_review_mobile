import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

/// Backend hazır olmadan dashboard'u geliştirmek için.
///
/// Trend ve şikayet verisi rapordaki örneğe uygun:
///   "En çok geçen negatif kelimeler: banyo, havlu, koku"
///   "Son 7 günde temizlik şikayetleri arttı" -> trend yükselen
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.summary});

  final DashboardSummary? summary;

  @override
  Future<DashboardSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return summary ?? _defaultSummary();
  }

  DashboardSummary _defaultSummary() {
    final now = DateTime.now();
    return DashboardSummary(
      todayReviewCount: 7,
      openActionCount: 3,
      negativeReviewCount: 12,
      totalReviewCount: 50,
      averageRating: 4.1,
      // Son 7 gün, sona doğru artan (kötüleşen) bir trend.
      negativeTrend: [
        for (var i = 6; i >= 0; i--)
          DailyNegativeCount(
            date: now.subtract(Duration(days: i)),
            count: switch (i) {
              6 => 1,
              5 => 1,
              4 => 2,
              3 => 2,
              2 => 3,
              1 => 4,
              _ => 5,
            },
          ),
      ],
      recurringComplaints: const [
        RecurringComplaint(keyword: 'banyo', count: 8),
        RecurringComplaint(keyword: 'havlu', count: 6),
        RecurringComplaint(keyword: 'koku', count: 5),
        RecurringComplaint(keyword: 'klima', count: 3),
        RecurringComplaint(keyword: 'gürültü', count: 2),
      ],
    );
  }
}