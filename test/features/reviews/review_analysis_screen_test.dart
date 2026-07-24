import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review_repository.dart';
import 'package:hotel_review_mobile/features/reviews/presentation/review_analysis_screen.dart';
import 'package:hotel_review_mobile/features/reviews/presentation/review_providers.dart';

import '../../helpers/pump_app.dart';

class _StubReviewRepository implements ReviewRepository {
  _StubReviewRepository(this.detail);

  final ReviewDetail detail;

  @override
  Future<Review> createReview(NewReview review) => throw UnimplementedError();

  @override
  Future<List<Review>> getMyReviews() async => const [];

  @override
  Future<ReviewDetail> getReviewDetail(String id) async => detail;
}

void main() {
  group('ReviewAnalysisScreen', () {
    testWidgets('her cümleyi kendi rozet/etiket/öneriyle ayrı kart olarak listeler', (
      tester,
    ) async {
      final detail = ReviewDetail(
        id: 'r1',
        comment: 'Genel olarak iyiydi ama bazı sorunlar vardı.',
        rating: 3,
        reviewDate: DateTime(2026, 7, 20),
        clauseAnalyses: const [
          ReviewClauseAnalysis(
            clauseText: 'Banyo çok kirliydi.',
            sentiment: Sentiment.negative,
            sentimentScore: -0.8,
            priority: 'Yüksek',
            categoryName: 'Temizlik',
            confidence: 0.9,
            suggestion: 'Temizlik kontrol listesi gözden geçirilmeli.',
          ),
          ReviewClauseAnalysis(
            clauseText: 'Kahvaltı çeşitliliği güzeldi.',
            sentiment: Sentiment.positive,
            sentimentScore: 0.6,
            priority: 'Bilgi',
            categoryName: 'Yemek',
            confidence: 0.7,
          ),
        ],
      );

      await tester.pumpApp(
        const ReviewAnalysisScreen(reviewId: 'r1'),
        overrides: [
          reviewRepositoryProvider.overrideWithValue(
            _StubReviewRepository(detail),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Detaylı Analiz'), findsOneWidget);

      // Her iki cümle de kendi metniyle görünmeli.
      expect(find.text('"Banyo çok kirliydi."'), findsOneWidget);
      expect(find.text('"Kahvaltı çeşitliliği güzeldi."'), findsOneWidget);

      // Kategori etiketleri.
      expect(find.text('Temizlik'), findsOneWidget);
      expect(find.text('Yemek'), findsOneWidget);

      // Sadece ilk cümlenin önerisi var.
      expect(
        find.textContaining('Temizlik kontrol listesi'),
        findsOneWidget,
      );
    });

    testWidgets('analiz yoksa boş durum gösterilir', (tester) async {
      final detail = ReviewDetail(
        id: 'r2',
        comment: 'Analiz yok.',
        rating: 4,
        reviewDate: DateTime(2026, 7, 22),
      );

      await tester.pumpApp(
        const ReviewAnalysisScreen(reviewId: 'r2'),
        overrides: [
          reviewRepositoryProvider.overrideWithValue(
            _StubReviewRepository(detail),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('AI analizi henüz yok'), findsOneWidget);
    });
  });
}
