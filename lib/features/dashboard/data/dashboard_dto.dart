import '../domain/dashboard_summary.dart';

/// GET /api/dashboard/summary
///
/// Backend'in döndüğü gerçek gövde:
///   { "totalReviews": 25, "averageRating": 4, "openActionItems": 16,
///     "negativeRatio": 48 }
///
/// Trend/kategori/anahtar kelime burada YOK - ayrı endpoint'lerden geliyor
/// (bkz. DailyRatingPointDto, CategoryDistributionItemDto, top-keywords).
/// Mobil bazı alanları farklı isimlerle bekliyordu; birden çok isim
/// deneniyor ki backend alan adlarını değiştirse de DTO çalışmaya devam etsin.
class DashboardSummaryDto {
  const DashboardSummaryDto({
    required this.todayReviewCount,
    required this.openActionCount,
    required this.negativeReviewCount,
    required this.totalReviews,
    this.averageRating,
  });

  final int todayReviewCount;
  final int openActionCount;
  final int negativeReviewCount;
  final int totalReviews;
  final double? averageRating;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    /// Verilen anahtarlardan ilk dolu olanı okur.
    num? readNum(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value;
      }
      return null;
    }

    int readInt(List<String> keys) => readNum(keys)?.toInt() ?? 0;

    final totalReviews = readInt(const ['totalReviews', 'totalReviewCount']);

    // Negatif yorum SAYISI doğrudan gelmiyorsa, ORANDAN türet.
    // Backend şu an sadece negativeRatio (yüzde) gönderiyor.
    var negativeCount = readInt(const [
      'negativeReviewCount',
      'negativeReviews',
      'negativeCount',
    ]);
    if (negativeCount == 0) {
      final ratio = readNum(const ['negativeRatio'])?.toDouble();
      if (ratio != null && totalReviews > 0) {
        negativeCount = (totalReviews * ratio / 100).round();
      }
    }

    return DashboardSummaryDto(
      todayReviewCount: readInt(const [
        'todayReviewCount',
        'todayReviews',
        'todaysReviewCount',
      ]),
      openActionCount: readInt(const [
        'openActionCount',
        'openActionItems',
        'openActions',
      ]),
      negativeReviewCount: negativeCount,
      totalReviews: totalReviews,
      averageRating: readNum(const ['averageRating', 'avgRating'])?.toDouble(),
    );
  }
}

/// GET /api/dashboard/trends
/// [{ "date": "2026-07-22", "averageRating": 4.27, "reviewCount": 11 }]
class DailyRatingPointDto {
  const DailyRatingPointDto({
    required this.date,
    required this.averageRating,
    required this.reviewCount,
  });

  final String date;
  final double averageRating;
  final int reviewCount;

  factory DailyRatingPointDto.fromJson(Map<String, dynamic> json) {
    return DailyRatingPointDto(
      date: json['date'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  DailyRatingPoint toDomain() => DailyRatingPoint(
    date: DateTime.tryParse(date) ?? DateTime.now(),
    averageRating: averageRating,
    reviewCount: reviewCount,
  );
}

/// GET /api/dashboard/category-distribution
/// [{ "categoryName": "Banyo & Tuvalet", "reviewCount": 9, "negativeRatio": 11.1 }]
class CategoryDistributionItemDto {
  const CategoryDistributionItemDto({
    required this.categoryName,
    required this.reviewCount,
    required this.negativeRatio,
  });

  final String categoryName;
  final int reviewCount;
  final double negativeRatio;

  factory CategoryDistributionItemDto.fromJson(Map<String, dynamic> json) {
    return CategoryDistributionItemDto(
      categoryName: json['categoryName'] as String? ?? 'Diğer',
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      negativeRatio: (json['negativeRatio'] as num?)?.toDouble() ?? 0,
    );
  }

  CategoryDistributionItem toDomain() => CategoryDistributionItem(
    categoryName: categoryName,
    reviewCount: reviewCount,
    negativeRatio: negativeRatio,
  );
}

/// GET /api/dashboard/top-keywords
/// [{ "keyword": "oda", "count": 6 }]
class RecurringComplaintDto {
  const RecurringComplaintDto({required this.keyword, required this.count});

  final String keyword;
  final int count;

  factory RecurringComplaintDto.fromJson(Map<String, dynamic> json) {
    return RecurringComplaintDto(
      keyword: (json['keyword'] ?? json['word'] ?? json['text'] ?? '')
          .toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  RecurringComplaint toDomain() =>
      RecurringComplaint(keyword: keyword, count: count);
}
