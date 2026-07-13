/// AI servisinin döndürdüğü duygu durumu (rapor bölüm 9).
/// review_analysis.sentiment sadece bu üç değeri alabilir.
enum Sentiment {
  positive,
  negative,
  neutral,
  unknown;

  static Sentiment fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'positive':
        return Sentiment.positive;
      case 'negative':
        return Sentiment.negative;
      case 'neutral':
        return Sentiment.neutral;
      default:
        return Sentiment.unknown;
    }
  }

  String get label => switch (this) {
        Sentiment.positive => 'Olumlu',
        Sentiment.negative => 'Olumsuz',
        Sentiment.neutral => 'Nötr',
        Sentiment.unknown => 'Bilinmiyor',
      };
}

/// Yorumun geldiği kanal (rapor bölüm 7: reviews.source).
enum ReviewSource {
  mobile,
  manual,
  import,
  api;

  String get apiValue => name;
}

/// Python AI servisinin ürettiği analiz sonucu (rapor bölüm 9).
class ReviewAnalysis {
  const ReviewAnalysis({
    required this.sentiment,
    required this.sentimentScore,
    required this.category,
    required this.keywords,
    this.summary,
    this.suggestion,
    required this.confidence,
  });

  final Sentiment sentiment;
  final double sentimentScore;
  final String category;
  final List<String> keywords;
  final String? summary;
  final String? suggestion;
  final double confidence;
}

/// Kaydedilmiş yorum. Analiz henüz gelmemişse `analysis` null olur
/// (AI servisi asenkron çalışıyorsa bu durum mümkün).
class Review {
  const Review({
    required this.id,
    required this.comment,
    required this.rating,
    required this.source,
    required this.reviewDate,
    this.guestName,
    this.analysis,
    this.photoUrl,
    this.ocrText,
  });

  final String id;
  final String comment;
  final int rating;
  final ReviewSource source;
  final DateTime reviewDate;
  final String? guestName;
  final ReviewAnalysis? analysis;
  final String? photoUrl;
  final String? ocrText;

  bool get isAnalyzed => analysis != null;
}

/// Kullanıcının forma girdiği, henüz kaydedilmemiş yorum.
///
/// `photoPath` bir dosya yolu (String) - domain katmanı `File` veya
/// image_picker'ın `XFile` tipini bilmemeli. Dosyaya çevirmek data katmanının işi.
class NewReview {
  const NewReview({
    required this.comment,
    required this.rating,
    this.guestName,
    this.photoPath,
  });

  final String comment;
  final int rating;
  final String? guestName;
  final String? photoPath;

  /// Rapor bölüm 7'deki entity kuralları.
  /// Domain kuralı domainde yaşar - hem formda hem repository'de kullanılabilir.
  static const int minCommentLength = 10;

  static String? validateComment(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Yorum boş olamaz.';
    if (text.length < minCommentLength) {
      return 'Yorum en az $minCommentLength karakter olmalıdır.';
    }
    return null;
  }

  static String? validateRating(int? value) {
    if (value == null) return 'Puan seçilmelidir.';
    if (value < 1 || value > 5) return 'Puan 1-5 aralığında olmalıdır.';
    return null;
  }
}