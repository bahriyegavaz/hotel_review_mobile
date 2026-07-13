import 'review.dart';

sealed class ReviewFailure implements Exception {
  const ReviewFailure(this.message);
  final String message;
}

class ReviewNetworkFailure extends ReviewFailure {
  const ReviewNetworkFailure()
      : super('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
}

class ReviewValidationFailure extends ReviewFailure {
  const ReviewValidationFailure(super.message);
}

/// Fotoğraf çok büyük ya da desteklenmeyen formatta
/// (rapor bölüm 12: "Dosyalar için boyut ve uzantı kontrolü yapılmalı").
class ReviewFileFailure extends ReviewFailure {
  const ReviewFileFailure(super.message);
}

class UnknownReviewFailure extends ReviewFailure {
  const UnknownReviewFailure([String? message])
      : super(message ?? 'Beklenmeyen bir hata oluştu.');
}

abstract class ReviewRepository {
  /// POST /api/mobile/reviews-with-photo
  /// Fotoğraf opsiyonel. Backend kaydeder, AI analizini tetikler
  /// ve kaydedilmiş yorumu döner.
  Future<Review> createReview(NewReview review);

  /// GET /api/reviews - şimdilik mobil için basit liste.
  Future<List<Review>> getMyReviews();
}