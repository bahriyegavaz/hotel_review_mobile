import '../domain/dashboard_summary.dart';

/// !!! BACKEND GELİNCE KONTROL EDİLECEK !!!
/// Rapor bölüm 8: GET /api/dashboard/summary + /api/dashboard/trends.
/// Trend ve şikayet verisi ayrı endpoint'ten de gelebilir - o durumda
/// ApiDashboardRepository iki çağrı yapıp birleştirir. Şimdilik tek
/// response'ta geldiğini varsayıyoruz. Alan adları tahmin.
class DashboardSummaryDto {
  const DashboardSummaryDto({
    required this.todayReviewCount,
    required this.openActionCount,
    required this.negativeReviewCount,
    required this.totalReviewCount,
    this.averageRating,
    this.negativeTrend = const [],
    this.recurringComplaints = const [],
  });

  final int todayReviewCount;
  final int openActionCount;
  final int negativeReviewCount;
  final int totalReviewCount;
  final double? averageRating;
  final List<DailyNegativeCount> negativeTrend;
  final List<RecurringComplaint> recurringComplaints;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    final trendRaw = json['negativeTrend'];
    final trend = trendRaw is List
        ? trendRaw.whereType<Map<String, dynamic>>().map((e) {
            return DailyNegativeCount(
              date: DateTime.tryParse(e['date'] as String? ?? '') ??
                  DateTime.now(),
              count: (e['count'] as num?)?.toInt() ?? 0,
            );
          }).toList()
        : <DailyNegativeCount>[];

    final complaintsRaw = json['recurringComplaints'];
    final complaints = complaintsRaw is List
        ? complaintsRaw.whereType<Map<String, dynamic>>().map((e) {
            return RecurringComplaint(
              keyword: e['keyword'] as String? ?? '',
              count: (e['count'] as num?)?.toInt() ?? 0,
            );
          }).toList()
        : <RecurringComplaint>[];

    return DashboardSummaryDto(
      todayReviewCount: readInt('todayReviewCount'),
      openActionCount: readInt('openActionCount'),
      negativeReviewCount: readInt('negativeReviewCount'),
      totalReviewCount: readInt('totalReviewCount'),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      negativeTrend: trend,
      recurringComplaints: complaints,
    );
  }

  DashboardSummary toDomain() => DashboardSummary(
        todayReviewCount: todayReviewCount,
        openActionCount: openActionCount,
        negativeReviewCount: negativeReviewCount,
        totalReviewCount: totalReviewCount,
        averageRating: averageRating,
        negativeTrend: negativeTrend,
        recurringComplaints: recurringComplaints,
      );
}