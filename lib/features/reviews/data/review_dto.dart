import '../domain/review.dart';

/// AI analiz sonucu (rapor bölüm 9'daki örnek response).
///
/// !!! BACKEND GELİNCE KONTROL EDİLECEK !!!
/// Rapordaki örnek camelCase: sentiment, sentimentScore, category,
/// keywords, summary, suggestion, confidence
class ReviewAnalysisDto {
  const ReviewAnalysisDto({
    required this.sentiment,
    required this.sentimentScore,
    required this.category,
    required this.keywords,
    this.summary,
    this.suggestion,
    required this.confidence,
  });

  final String sentiment;
  final double sentimentScore;
  final String category;
  final List<String> keywords;
  final String? summary;
  final String? suggestion;
  final double confidence;

  factory ReviewAnalysisDto.fromJson(Map<String, dynamic> json) {
    return ReviewAnalysisDto(
      sentiment: json['sentiment'] as String? ?? '',
      // int de double da gelebilir - num üzerinden geçiyoruz.
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      summary: json['summary'] as String?,
      suggestion: json['suggestion'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  ReviewAnalysis toDomain() => ReviewAnalysis(
        sentiment: Sentiment.fromString(sentiment),
        sentimentScore: sentimentScore,
        category: category,
        keywords: keywords,
        summary: summary,
        suggestion: suggestion,
        confidence: confidence,
      );
}

class ReviewDto {
  const ReviewDto({
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
  final String source;
  final String reviewDate;
  final String? guestName;
  final ReviewAnalysisDto? analysis;
  final String? photoUrl;
  final String? ocrText;

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    final rawAnalysis = json['analysis'];
    return ReviewDto(
      id: json['id']?.toString() ?? '',
      comment: json['comment'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'mobile',
      reviewDate: json['reviewDate'] as String? ?? '',
      guestName: json['guestName'] as String?,
      analysis: rawAnalysis is Map<String, dynamic>
          ? ReviewAnalysisDto.fromJson(rawAnalysis)
          : null,
      photoUrl: json['photoUrl'] as String?,
      ocrText: json['ocrText'] as String?,
    );
  }

  Review toDomain() => Review(
        id: id,
        comment: comment,
        rating: rating,
        source: ReviewSource.values.firstWhere(
          (s) => s.name.toLowerCase() == source.toLowerCase(),
          orElse: () => ReviewSource.mobile,
        ),
        // Bozuk tarih gelirse çökmesin.
        reviewDate: DateTime.tryParse(reviewDate) ?? DateTime.now(),
        guestName: guestName,
        analysis: analysis?.toDomain(),
        photoUrl: photoUrl,
        ocrText: ocrText,
      );
}