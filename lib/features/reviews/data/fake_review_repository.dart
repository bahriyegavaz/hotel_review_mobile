import '../domain/review.dart';
import '../domain/review_repository.dart';

/// Backend hazır olmadan yorum ekleme akışını geliştirmek için.
/// Basit bir kural tabanlı "sahte AI" içerir - gerçek AI servisinin
/// döneceği şeye benzer sonuç üretir ki UI'ı test edebilelim.
///
/// Hata senaryosu testi:
///   Yorum içinde "hata" kelimesi geçerse ReviewNetworkFailure fırlatır.
class FakeReviewRepository implements ReviewRepository {
  // Uygulama açık kaldığı sürece yaşayan sahte veritabanı.
  final List<Review> _reviews = [];
  int _nextId = 1;

  @override
  Future<Review> createReview(NewReview newReview) async {
    if (newReview.comment.toLowerCase().contains('hata')) {
      await Future<void>.delayed(const Duration(seconds: 2));
      throw const ReviewNetworkFailure();
    }

    // Yorum kaydı + AI analizi gerçekte biraz sürer.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final review = Review(
      id: '${_nextId++}',
      comment: newReview.comment,
      rating: newReview.rating,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now(),
      guestName: newReview.guestName,
      photoUrl: newReview.photoPath,
      ocrText: newReview.photoPath != null
          ? 'Sahte OCR sonucu: fotoğraftan metin okunamadı.'
          : null,
      analysis: _fakeAnalyze(newReview.comment, newReview.rating),
    );

    _reviews.insert(0, review);
    return review;
  }

  @override
  Future<List<Review>> getMyReviews() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_reviews);
  }

  /// Rapor bölüm 9'daki "keyword matching" yaklaşımının en ilkel hali.
  /// Gerçek Python servisi geldiğinde bu tamamen devre dışı kalacak.
  ReviewAnalysis _fakeAnalyze(String comment, int rating) {
    final text = comment.toLowerCase();

    const categoryKeywords = <String, List<String>>{
      'Temizlik': ['banyo', 'havlu', 'koku', 'kirli', 'temiz', 'çarşaf'],
      'Yemek': ['kahvaltı', 'yemek', 'lezzet', 'restoran', 'menü'],
      'Personel': ['personel', 'resepsiyon', 'ilgi', 'kaba', 'güler'],
      'Oda': ['oda', 'yatak', 'klima', 'manzara', 'gürültü'],
      'Fiyat': ['fiyat', 'pahalı', 'ucuz', 'ücret'],
    };

    var category = 'Genel';
    final matched = <String>[];

    for (final entry in categoryKeywords.entries) {
      final hits = entry.value.where(text.contains).toList();
      if (hits.isNotEmpty) {
        category = entry.key;
        matched.addAll(hits);
        break;
      }
    }

    // Puanı sentiment'in ana sinyali olarak kullanıyoruz.
    final sentiment = switch (rating) {
      >= 4 => Sentiment.positive,
      3 => Sentiment.neutral,
      _ => Sentiment.negative,
    };

    final score = switch (sentiment) {
      Sentiment.positive => 0.75,
      Sentiment.neutral => 0.0,
      _ => -0.72,
    };

    return ReviewAnalysis(
      sentiment: sentiment,
      sentimentScore: score,
      category: category,
      keywords: matched.isEmpty ? const ['genel'] : matched,
      summary: 'Misafir $category kategorisinde geri bildirim verdi.',
      suggestion: sentiment == Sentiment.negative
          ? '$category ile ilgili departman kontrol listesi gözden geçirilmeli.'
          : null,
      confidence: 0.65,
    );
  }
}