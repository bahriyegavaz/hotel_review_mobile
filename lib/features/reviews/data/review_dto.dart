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
      category: json['category'] as String? ?? 'Genel',
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
      photoUrl: json['photoUrl'] as String? ?? _firstAttachmentUrl(json),
      ocrText: json['ocrText'] as String?,
    );
  }

  /// Backend fotoğrafı düz `photoUrl` yerine ReviewAttachments tablosundan
  /// `attachments: [{ fileUrl }]` dizisi olarak dönebiliyor. İkisi de olabilir,
  /// hangisi geldiyse onu kullan.
  static String? _firstAttachmentUrl(Map<String, dynamic> json) {
    final attachments = json['attachments'];
    if (attachments is! List || attachments.isEmpty) return null;

    final first = attachments.first;
    if (first is! Map<String, dynamic>) return null;

    return first['fileUrl'] as String? ??
        first['url'] as String? ??
        first['photoUrl'] as String?;
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

/// review_attachments tablosu - GET /api/reviews/{id} response'unda gelir.
class ReviewAttachmentDto {
  const ReviewAttachmentDto({required this.fileUrl, this.ocrText});

  final String fileUrl;
  final String? ocrText;

  factory ReviewAttachmentDto.fromJson(Map<String, dynamic> json) {
    return ReviewAttachmentDto(
      fileUrl: json['fileUrl'] as String? ?? '',
      ocrText: json['ocrText'] as String?,
    );
  }

  ReviewAttachment toDomain() =>
      ReviewAttachment(fileUrl: fileUrl, ocrText: ocrText);
}

/// review_analyses tablosu - AI'ın cümle bazlı ABSA çıktısı.
/// Sadece GET /api/reviews/{id}'de gelir, listede yok.
class ReviewClauseAnalysisDto {
  const ReviewClauseAnalysisDto({
    required this.clauseText,
    required this.sentiment,
    required this.sentimentScore,
    required this.priority,
    required this.categoryName,
    required this.confidence,
    this.suggestion,
  });

  final String clauseText;
  final String sentiment;
  final double sentimentScore;
  final String priority;
  final String categoryName;
  final double confidence;
  final String? suggestion;

  factory ReviewClauseAnalysisDto.fromJson(Map<String, dynamic> json) {
    return ReviewClauseAnalysisDto(
      clauseText: json['clauseText'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? '',
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0,
      priority: json['priority'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Genel',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      suggestion: json['suggestion'] as String?,
    );
  }

  ReviewClauseAnalysis toDomain() => ReviewClauseAnalysis(
        clauseText: clauseText,
        sentiment: Sentiment.fromString(sentiment),
        sentimentScore: sentimentScore,
        priority: priority,
        categoryName: categoryName,
        confidence: confidence,
        suggestion: suggestion,
      );
}

/// GET /api/reviews/{id} - liste DTO'sundan farklı olarak attachments ve
/// analyses dizilerini de içerir.
class ReviewDetailDto {
  const ReviewDetailDto({
    required this.id,
    required this.comment,
    required this.rating,
    required this.reviewDate,
    this.guestName,
    this.attachments = const [],
    this.analyses = const [],
  });

  final String id;
  final String comment;
  final int rating;
  final String reviewDate;
  final String? guestName;
  final List<ReviewAttachmentDto> attachments;
  final List<ReviewClauseAnalysisDto> analyses;

  factory ReviewDetailDto.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final rawAnalyses = json['analyses'];

    return ReviewDetailDto(
      id: json['id']?.toString() ?? '',
      comment: json['comment'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewDate: json['reviewDate'] as String? ?? '',
      guestName: json['guestName'] as String?,
      attachments: rawAttachments is List
          ? rawAttachments
              .whereType<Map<String, dynamic>>()
              .map(ReviewAttachmentDto.fromJson)
              .toList()
          : const [],
      analyses: rawAnalyses is List
          ? rawAnalyses
              .whereType<Map<String, dynamic>>()
              .map(ReviewClauseAnalysisDto.fromJson)
              .toList()
          : const [],
    );
  }

  ReviewDetail toDomain() => ReviewDetail(
        id: id,
        comment: comment,
        rating: rating,
        reviewDate: DateTime.tryParse(reviewDate) ?? DateTime.now(),
        guestName: guestName,
        attachments: attachments.map((a) => a.toDomain()).toList(),
        clauseAnalyses: analyses.map((a) => a.toDomain()).toList(),
      );
}