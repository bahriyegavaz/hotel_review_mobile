/// Rapor bölüm 11: "Basit dashboard kartları: bugün gelen yorum,
/// açık aksiyon, negatif yorum sayısı."
///
/// Web paneli (bölüm 10) daha zengin: grafikler, trendler.
/// Mobilde saha personeli için sade tutuyoruz.
class DashboardSummary {
  const DashboardSummary({
    required this.todayReviewCount,
    required this.openActionCount,
    required this.negativeReviewCount,
    required this.totalReviewCount,
    this.averageRating,
  });

  /// Bugün eklenen yorum sayısı.
  final int todayReviewCount;

  /// Açık + devam eden aksiyonlar (kapanmamış olanlar).
  final int openActionCount;

  /// Negatif duygu içeren yorum sayısı.
  final int negativeReviewCount;

  final int totalReviewCount;

  /// 1-5 arası. Backend göndermezse null.
  final double? averageRating;

  /// Negatif yorum oranı - yüzde olarak.
  /// Sıfıra bölme koruması: hiç yorum yoksa 0 döner.
  double get negativeRatio {
    if (totalReviewCount == 0) return 0;
    return negativeReviewCount / totalReviewCount * 100;
  }

  /// Rapordaki örnek çıktı: "negatif oran %24" gibi bir eşik uyarısı.
  bool get hasHighNegativeRatio => negativeRatio > 20;

  static const empty = DashboardSummary(
    todayReviewCount: 0,
    openActionCount: 0,
    negativeReviewCount: 0,
    totalReviewCount: 0,
  );
}