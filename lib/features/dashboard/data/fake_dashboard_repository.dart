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
      // Son 7 gün, sona doğru düşen (kötüleşen) bir puan trendi.
      ratingTrend: [
        for (var i = 6; i >= 0; i--)
          DailyRatingPoint(
            date: now.subtract(Duration(days: i)),
            averageRating: switch (i) {
              6 => 4.6,
              5 => 4.5,
              4 => 4.3,
              3 => 4.1,
              2 => 3.8,
              1 => 3.5,
              _ => 3.2,
            },
            reviewCount: switch (i) {
              6 => 4,
              5 => 6,
              4 => 5,
              3 => 8,
              2 => 7,
              1 => 9,
              _ => 11,
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
      categoryDistribution: const [
        CategoryDistributionItem(
          categoryName: 'Temizlik',
          reviewCount: 14,
          negativeRatio: 42,
        ),
        CategoryDistributionItem(
          categoryName: 'Yemek Kalitesi',
          reviewCount: 10,
          negativeRatio: 30,
        ),
        CategoryDistributionItem(
          categoryName: 'Personel Hizmeti',
          reviewCount: 8,
          negativeRatio: 12.5,
        ),
        CategoryDistributionItem(
          categoryName: 'Oda Konforu',
          reviewCount: 6,
          negativeRatio: 16.7,
        ),
        CategoryDistributionItem(
          categoryName: 'Resepsiyon Hizmeti',
          reviewCount: 4,
          negativeRatio: 0,
        ),
      ],
    );
  }
}
