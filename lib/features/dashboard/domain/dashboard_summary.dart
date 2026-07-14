/// Rapor bölüm 11: "Basit dashboard kartları: bugün gelen yorum,
/// açık aksiyon, negatif yorum sayısı."
///
/// Rapor bölüm 1 (beklenen çıktı) + bölüm 8 (/dashboard/trends):
///   - "Son 7 günde temizlik şikayetleri %24 arttı"
///   - "En çok geçen negatif kelimeler: banyo, havlu, koku"
/// Negatif detayı bu iki veriyi gösterir

/// Bir günün negatif yorum sayısı - trend grafiği için.
class DailyNegativeCount {
  const DailyNegativeCount({required this.date, required this.count});

  final DateTime date;
  final int count;
}

/// Tekrar eden bir şikayet: kelime/konu ve kaç kez geçtiği.
class RecurringComplaint {
  const RecurringComplaint({required this.keyword, required this.count});

  final String keyword;
  final int count;
}

class DashboardSummary {
  const DashboardSummary({
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

  /// Son günlerin negatif yorum sayıları (eskiden yeniye).
  /// Negatif kartı açılınca gösterilir.
  final List<DailyNegativeCount> negativeTrend;

  /// En sık tekrar eden şikayet kelimeleri.
  final List<RecurringComplaint> recurringComplaints;

  double get negativeRatio {
    if (totalReviewCount == 0) return 0;
    return negativeReviewCount / totalReviewCount * 100;
  }

  bool get hasHighNegativeRatio => negativeRatio > 20;

  /// Trend son iki günü karşılaştırarak artıyor mu düşüyor mu.
  /// null = yeterli veri yok.
  bool? get isNegativeTrendRising {
    if (negativeTrend.length < 2) return null;
    return negativeTrend.last.count > negativeTrend[negativeTrend.length - 2].count;
  }

  /// Grafik ölçeklemesi için trenddeki en yüksek değer.
  int get maxTrendCount {
    if (negativeTrend.isEmpty) return 0;
    return negativeTrend.map((d) => d.count).reduce((a, b) => a > b ? a : b);
  }

  static const empty = DashboardSummary(
    todayReviewCount: 0,
    openActionCount: 0,
    negativeReviewCount: 0,
    totalReviewCount: 0,
  );
}