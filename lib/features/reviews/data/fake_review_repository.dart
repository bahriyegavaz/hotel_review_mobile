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
  final List<Review> _reviews = [
     Review(
      id: 'seed-1',
      comment:
          'Oda çok temizdi, personel son derece ilgiliydi. Kahvaltı '
          'zengindi, kesinlikle tekrar geleceğiz.',
      rating: 5,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now().subtract(const Duration(hours: 3)),
      guestName: 'Ayşe Yılmaz',
      analysis: const ReviewAnalysis(
        sentiment: Sentiment.positive,
        sentimentScore: 0.8,
        category: 'Personel',
        keywords: ['temiz', 'ilgi', 'kahvaltı'],
        summary: 'Misafir Personel kategorisinde olumlu geri bildirim verdi.',
        confidence: 0.7,
      ),
    ),
    Review(
      id: 'seed-2',
      comment:
          'Banyoda koku vardı ve havlular değiştirilmemişti. '
          'Temizlik konusunda sıkıntı yaşadık.',
      rating: 2,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now().subtract(const Duration(days: 1)),
      guestName: 'Mehmet Demir',
      analysis: const ReviewAnalysis(
        sentiment: Sentiment.negative,
        sentimentScore: -0.7,
        category: 'Temizlik',
        keywords: ['banyo', 'koku', 'havlu'],
        summary: 'Misafir Temizlik kategorisinde olumsuz geri bildirim verdi.',
        suggestion:
            'Temizlik ile ilgili departman kontrol listesi gözden geçirilmeli.',
        confidence: 0.68,
      ),
    ),
    Review(
      id: 'seed-3',
      comment:
          'Konum güzeldi ama oda beklediğimden küçüktü. Fiyata göre ortalama.',
      rating: 3,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now().subtract(const Duration(days: 2)),
      guestName: 'Zeynep Kaya',
      analysis: const ReviewAnalysis(
        sentiment: Sentiment.neutral,
        sentimentScore: 0.0,
        category: 'Oda',
        keywords: ['oda', 'konum'],
        summary: 'Misafir Oda kategorisinde nötr geri bildirim verdi.',
        confidence: 0.6,
      ),
    ),
    Review(
      id: 'seed-4',
      comment:
          'Kahvaltı büfesi harikaydı, özellikle yöresel lezzetler çok '
          'başarılı. Restoran personeli de güler yüzlüydü.',
      rating: 5,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now().subtract(const Duration(days: 3)),
      guestName: 'Ali Vural',
      analysis: const ReviewAnalysis(
        sentiment: Sentiment.positive,
        sentimentScore: 0.85,
        category: 'Yemek',
        keywords: ['kahvaltı', 'restoran', 'lezzet'],
        summary: 'Misafir Yemek kategorisinde olumlu geri bildirim verdi.',
        confidence: 0.72,
      ),
    ),
    Review(
      id: 'seed-5',
      comment:
          'Klima gece boyunca ses yaptı, uyuyamadık. Resepsiyona '
          'bildirdik ama çözüm gelmedi.',
      rating: 2,
      source: ReviewSource.mobile,
      reviewDate: DateTime.now().subtract(const Duration(days: 4)),
      guestName: 'Fatma Şahin',
      analysis: const ReviewAnalysis(
        sentiment: Sentiment.negative,
        sentimentScore: -0.65,
        category: 'Oda',
        keywords: ['klima', 'gürültü'],
        summary: 'Misafir Oda kategorisinde olumsuz geri bildirim verdi.',
        suggestion: 'Oda ile ilgili teknik kontrol listesi gözden geçirilmeli.',
        confidence: 0.66,
      ),
    ),
  ];
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