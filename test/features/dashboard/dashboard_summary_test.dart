import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/dashboard/domain/dashboard_summary.dart';

DailyRatingPoint _point(int day, double rating) => DailyRatingPoint(
  date: DateTime(2026, 7, day),
  averageRating: rating,
  reviewCount: 1,
);

void main() {
  group('DashboardSummary.recentRatingTrend', () {
    test('7 veya daha az nokta varsa hepsini döner', () {
      final summary = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        ratingTrend: [_point(1, 3), _point(2, 4), _point(3, 5)],
      );

      expect(summary.recentRatingTrend, hasLength(3));
    });

    test('7\'den fazla nokta varsa sadece son 7\'sini döner', () {
      // Backend /api/dashboard/trends "son 7 gün" ile sınırlamıyor - ayları
      // kapsayan bir liste dönebiliyor. Grafiğin X ekseni etiketleri üst
      // üste binmesin diye burada kesmemiz gerekiyor.
      final allPoints = [for (var i = 1; i <= 29; i++) _point(i, i.toDouble())];
      final summary = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        ratingTrend: allPoints,
      );

      final recent = summary.recentRatingTrend;
      expect(recent, hasLength(7));
      // Son 7 gün = 23'ten 29'a kadar olan günler.
      expect(recent.first.date.day, 23);
      expect(recent.last.date.day, 29);
    });
  });
}
