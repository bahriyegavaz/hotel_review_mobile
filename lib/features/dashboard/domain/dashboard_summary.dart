/// Rapor bölüm 11: "Basit dashboard kartları: bugün gelen yorum,
/// açık aksiyon, negatif yorum sayısı."
///
/// Rapor bölüm 1 (beklenen çıktı) + bölüm 8 (/dashboard/trends):
///   - "Son 7 günde temizlik şikayetleri %24 arttı"
///   - "En çok geçen negatif kelimeler: banyo, havlu, koku"
/// Negatif detayı bu iki veriyi gösterir
library;

/// Bir günün ortalama puanı ve yorum sayısı - trend grafiği için.
/// GET /api/dashboard/trends
class DailyRatingPoint {
  const DailyRatingPoint({
    required this.date,
    required this.averageRating,
    required this.reviewCount,
  });

  final DateTime date;
  final double averageRating;
  final int reviewCount;
}

/// Tekrar eden bir şikayet: kelime/konu ve kaç kez geçtiği.
/// GET /api/dashboard/top-keywords
class RecurringComplaint {
  const RecurringComplaint({required this.keyword, required this.count});

  final String keyword;
  final int count;
}

/// Bir kategorideki yorum hacmi ve negatiflik oranı.
/// GET /api/dashboard/category-distribution
class CategoryDistributionItem {
  const CategoryDistributionItem({
    required this.categoryName,
    required this.reviewCount,
    required this.negativeRatio,
  });

  final String categoryName;
  final int reviewCount;

  /// 0-100 arası yüzde.
  final double negativeRatio;
}

class DashboardSummary {
  const DashboardSummary({
    required this.todayReviewCount,
    required this.openActionCount,
    required this.negativeReviewCount,
    required this.totalReviewCount,
    this.averageRating,
    this.ratingTrend = const [],
    this.recurringComplaints = const [],
    this.categoryDistribution = const [],
  });

  final int todayReviewCount;
  final int openActionCount;
  final int negativeReviewCount;
  final int totalReviewCount;
  final double? averageRating;

  /// Son günlerin ortalama puanı ve yorum sayısı (eskiden yeniye).
  final List<DailyRatingPoint> ratingTrend;

  /// En sık tekrar eden şikayet kelimeleri.
  final List<RecurringComplaint> recurringComplaints;

  /// Kategori başına yorum hacmi ve negatiflik oranı.
  final List<CategoryDistributionItem> categoryDistribution;

  double get negativeRatio {
    if (totalReviewCount == 0) return 0;
    return negativeReviewCount / totalReviewCount * 100;
  }

  bool get hasHighNegativeRatio => negativeRatio > 20;

  /// Trend son iki günü karşılaştırarak puan düşüyor mu.
  /// true = kötüleşiyor (erken uyarı). null = yeterli veri yok.
  bool? get isRatingTrendDeclining {
    if (ratingTrend.length < 2) return null;
    return ratingTrend.last.averageRating <
        ratingTrend[ratingTrend.length - 2].averageRating;
  }

  /// Grafikte gösterilecek son 7 gün.
  ///
  /// Backend GET /api/dashboard/trends "son 7 gün" ile sınırlamıyor - veri
  /// olan bütün günleri dönüyor (haftalarca geriye gidebiliyor). Hepsini
  /// çizersek X ekseni etiketleri üst üste biner ("Son 7 Gün" başlığı da
  /// yalan olur). O yüzden son 7 kaydı burada kesiyoruz.
  List<DailyRatingPoint> get recentRatingTrend => ratingTrend.length <= 7
      ? ratingTrend
      : ratingTrend.sublist(ratingTrend.length - 7);

  static const empty = DashboardSummary(
    todayReviewCount: 0,
    openActionCount: 0,
    negativeReviewCount: 0,
    totalReviewCount: 0,
  );
}
