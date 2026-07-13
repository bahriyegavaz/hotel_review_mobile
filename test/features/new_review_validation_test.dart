import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review.dart';

/// Rapor bölüm 7'deki entity kuralları:
///   "Review.comment boş olamaz ve en az 10 karakter olmalıdır."
///   "Review.rating 1-5 aralığında olmalıdır."
///
/// Bu testler widget veya ağ gerektirmez, milisaniyeler içinde çalışır.
/// Domain kuralları burada yaşadığı için hem formdan hem de import
/// akışından aynı doğrulama kullanılabilir.
void main() {
  group('NewReview.validateComment', () {
    test('boş yorumu reddeder', () {
      expect(NewReview.validateComment(''), 'Yorum boş olamaz.');
      expect(NewReview.validateComment(null), 'Yorum boş olamaz.');
      expect(NewReview.validateComment('   '), 'Yorum boş olamaz.');
    });

    test('10 karakterden kısa yorumu reddeder', () {
      final result = NewReview.validateComment('Kısa');
      expect(result, contains('en az 10 karakter'));
    });

    test('tam 10 karakteri kabul eder (sınır değeri)', () {
      expect(NewReview.validateComment('1234567890'), isNull);
    });

    test('baştaki/sondaki boşlukları sayarken kırpar', () {
      // "  Kısa  " -> trim sonrası 4 karakter, reddedilmeli
      expect(NewReview.validateComment('  Kısa  '), isNotNull);
    });

    test('geçerli yorumu kabul eder', () {
      expect(
        NewReview.validateComment('Banyoda kötü bir koku vardı.'),
        isNull,
      );
    });
  });

  group('NewReview.validateRating', () {
    test('null puanı reddeder', () {
      expect(NewReview.validateRating(null), 'Puan seçilmelidir.');
    });

    test('aralık dışı puanları reddeder', () {
      expect(NewReview.validateRating(0), contains('1-5'));
      expect(NewReview.validateRating(6), contains('1-5'));
      expect(NewReview.validateRating(-1), contains('1-5'));
    });

    test('1 ve 5 sınır değerlerini kabul eder', () {
      expect(NewReview.validateRating(1), isNull);
      expect(NewReview.validateRating(5), isNull);
    });
  });

  group('Sentiment.fromString', () {
    test('büyük/küçük harf duyarsız çalışır', () {
      expect(Sentiment.fromString('Positive'), Sentiment.positive);
      expect(Sentiment.fromString('NEGATIVE'), Sentiment.negative);
      expect(Sentiment.fromString('neutral'), Sentiment.neutral);
    });

    test('tanımadığı değer için unknown döner, çökmez', () {
      expect(Sentiment.fromString('Karışık'), Sentiment.unknown);
      expect(Sentiment.fromString(null), Sentiment.unknown);
      expect(Sentiment.fromString(''), Sentiment.unknown);
    });
  });
}