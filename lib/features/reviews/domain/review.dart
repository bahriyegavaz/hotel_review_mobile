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

/// AI'ın yorumu cümle cümle böldüğü ABSA analiz satırı (rapor bölüm 9).
/// review_analyses tablosundan geliyor - GET /api/reviews/{id} ile gelir,
/// listede (GET /api/reviews) yer almaz.
class ReviewClauseAnalysis {
  const ReviewClauseAnalysis({
    required this.clauseText,
    required this.sentiment,
    required this.sentimentScore,
    required this.priority,
    required this.categoryName,
    required this.confidence,
    this.suggestion,
  });

  final String clauseText;
  final Sentiment sentiment;
  final double sentimentScore;
  final String priority;
  final String categoryName;
  final double confidence;
  final String? suggestion;
}

/// Cümle bazlı analizlerden türetilen tek bir "genel" özet.
///
/// Backend review başına ayrı bir genel sentiment alanı sağlamıyor -
/// sadece cümle cümle (`ReviewClauseAnalysis`) veriyor. Kullanıcıya cümle
/// cümle kırılım yerine tek bir özet göstermek için bunu mobilde
/// hesaplıyoruz.
class ReviewOverallAnalysis {
  const ReviewOverallAnalysis({
    required this.sentiment,
    required this.averageScore,
    required this.priority,
    required this.categories,
    required this.suggestions,
    required this.confidence,
    this.highlightedClause,
  });

  final Sentiment sentiment;
  final double averageScore;
  final String priority;
  final List<String> categories;
  final List<String> suggestions;

  /// Cümlelerin ortalama AI güven oranı (backend her cümle satırına aynı
  /// review-seviyesi değeri kopyaladığı için pratikte hepsi eşit).
  final double confidence;

  /// En olumsuz (skoru en düşük) cümle - backend ayrı bir "özet" alanı
  /// döndürmediği için müşteri şikayetini temsilen bunu gösteriyoruz.
  final String? highlightedClause;

  factory ReviewOverallAnalysis.fromClauses(
    List<ReviewClauseAnalysis> clauses,
  ) {
    final sentimentCounts = <Sentiment, int>{};
    var scoreSum = 0.0;
    var confidenceSum = 0.0;
    final categories = <String>[];
    final suggestions = <String>[];
    String? topPriority;
    var topPriorityRank = -1;
    ReviewClauseAnalysis? mostNegativeClause;

    for (final clause in clauses) {
      sentimentCounts.update(
        clause.sentiment,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      scoreSum += clause.sentimentScore;
      confidenceSum += clause.confidence;

      if (!categories.contains(clause.categoryName)) {
        categories.add(clause.categoryName);
      }

      final suggestion = clause.suggestion;
      if (suggestion != null &&
          suggestion.isNotEmpty &&
          !suggestions.contains(suggestion)) {
        suggestions.add(suggestion);
      }

      final rank = _priorityRank(clause.priority);
      if (rank > topPriorityRank) {
        topPriorityRank = rank;
        topPriority = clause.priority;
      }

      if (mostNegativeClause == null ||
          clause.sentimentScore < mostNegativeClause.sentimentScore) {
        mostNegativeClause = clause;
      }
    }

    // En sık geçen duygu baskın kabul edilir (eşitlikte ilk bulunan kazanır).
    final dominantSentiment = sentimentCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return ReviewOverallAnalysis(
      sentiment: dominantSentiment,
      averageScore: clauses.isEmpty ? 0 : scoreSum / clauses.length,
      priority: topPriority ?? 'Bilgi',
      categories: categories,
      suggestions: suggestions.take(2).toList(),
      confidence: clauses.isEmpty ? 0 : confidenceSum / clauses.length,
      highlightedClause: mostNegativeClause?.clauseText,
    );
  }

  static int _priorityRank(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
      case 'yuksek':
        return 3;
      case 'orta':
        return 2;
      case 'düşük':
      case 'dusuk':
        return 1;
      default:
        return 0;
    }
  }
}

/// Bir yoruma ait fotoğraf (review_attachments tablosu).
class ReviewAttachment {
  const ReviewAttachment({required this.fileUrl, this.ocrText});

  final String fileUrl;
  final String? ocrText;
}

/// GET /api/reviews/{id} - liste görünümünden farklı olarak fotoğrafları
/// ve cümle bazlı AI analizini de içerir.
class ReviewDetail {
  const ReviewDetail({
    required this.id,
    required this.comment,
    required this.rating,
    required this.reviewDate,
    this.guestName,
    this.attachments = const [],
    this.clauseAnalyses = const [],
  });

  final String id;
  final String comment;
  final int rating;
  final DateTime reviewDate;
  final String? guestName;
  final List<ReviewAttachment> attachments;
  final List<ReviewClauseAnalysis> clauseAnalyses;

  ReviewOverallAnalysis? get overallAnalysis => clauseAnalyses.isEmpty
      ? null
      : ReviewOverallAnalysis.fromClauses(clauseAnalyses);
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
