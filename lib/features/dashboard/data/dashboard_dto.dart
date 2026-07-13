import '../domain/dashboard_summary.dart';

/// !!! BACKEND GELİNCE KONTROL EDİLECEK !!!
/// Alan adları tahmin. Rapor bölüm 8 sadece "KPI kartları için özet veri döner"
/// diyor, şemayı vermiyor. Stajyer 2 ile netleşecek.
class DashboardSummaryDto {
  const DashboardSummaryDto({
    required this.todayReviewCount,
    required this.openActionCount,
    required this.negativeReviewCount,
    required this.totalReviewCount,
    this.averageRating,
  });

  final int todayReviewCount;
  final int openActionCount;
  final int negativeReviewCount;
  final int totalReviewCount;
  final double? averageRating;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    // num üzerinden geçiyoruz: backend int de double da gönderebilir.
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return DashboardSummaryDto(
      todayReviewCount: readInt('todayReviewCount'),
      openActionCount: readInt('openActionCount'),
      negativeReviewCount: readInt('negativeReviewCount'),
      totalReviewCount: readInt('totalReviewCount'),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }

  DashboardSummary toDomain() => DashboardSummary(
        todayReviewCount: todayReviewCount,
        openActionCount: openActionCount,
        negativeReviewCount: negativeReviewCount,
        totalReviewCount: totalReviewCount,
        averageRating: averageRating,
      );
}