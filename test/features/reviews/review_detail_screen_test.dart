import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/action_items/data/fake_action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_item_providers.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review_repository.dart';
import 'package:hotel_review_mobile/features/reviews/presentation/review_detail_screen.dart';
import 'package:hotel_review_mobile/features/reviews/presentation/review_providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

/// Testlerde kontrollü bir ReviewDetail dönmek için - FakeReviewRepository
/// her yorum için tek cümle üretiyor, ama özet kartının birden fazla
/// kategori/öneriyi doğru birleştirdiğini görmek için çok cümleli bir
/// senaryo gerekiyor.
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

/// AI'ın bu yorum için zaten oluşturduğu aksiyonu simüle etmek için -
/// "Aksiyon Ekle" formunun varsayılan önerisi/departmanı bunlardan gelmeli.
class _StubActionItemRepository implements ActionItemRepository {
  _StubActionItemRepository(this._items);

  final List<ActionItem> _items;

  @override
  Future<List<ActionItem>> getActionItems() async => _items;

  @override
  Future<void> updateStatus({
    required String id,
    required ActionStatus status,
  }) async => throw UnimplementedError();

  @override
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  }) async => throw UnimplementedError();

  @override
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return ActionItem(
      id: 'new-1',
      title: title,
      status: ActionStatus.open,
      departmentId: departmentId,
      departmentName: departmentName,
      reviewId: reviewId,
      dueDate: dueDate,
    );
  }
}

const _cleaningClause = ReviewClauseAnalysis(
  clauseText: 'Banyo çok kirliydi ve havlular değiştirilmemişti.',
  sentiment: Sentiment.negative,
  sentimentScore: -0.8,
  priority: 'Yüksek',
  categoryName: 'Temizlik',
  confidence: 0.9,
  suggestion: 'Temizlik departmanı oda çıkış kontrol listesini gözden geçirmeli.',
);

const _foodClause = ReviewClauseAnalysis(
  clauseText: 'Kahvaltı çeşitliliği güzeldi.',
  sentiment: Sentiment.positive,
  sentimentScore: 0.6,
  priority: 'Bilgi',
  categoryName: 'Yemek',
  confidence: 0.7,
);

const _roomClause = ReviewClauseAnalysis(
  clauseText: 'Oda biraz küçüktü ama manzara iyiydi.',
  sentiment: Sentiment.neutral,
  sentimentScore: -0.2,
  priority: 'Orta',
  categoryName: 'Oda',
  confidence: 0.8,
  suggestion: 'Oda büyüklüğü beklentisi rezervasyon sayfasında netleştirilmeli.',
);

final _multiClauseDetail = ReviewDetail(
  id: 'r1',
  comment: 'Genel olarak iyiydi ama bazı sorunlar vardı.',
  rating: 3,
  reviewDate: DateTime(2026, 7, 20),
  guestName: 'Test Misafir',
  clauseAnalyses: const [_cleaningClause, _foodClause, _roomClause],
);

void main() {
  group('ReviewDetailScreen özet kartı', () {
    testWidgets('birincil kategori, güven oranı ve öne çıkan şikayeti gösterir', (
      tester,
    ) async {
      await tester.pumpApp(
        const ReviewDetailScreen(reviewId: 'r1'),
        overrides: [
          reviewRepositoryProvider.overrideWithValue(
            _StubReviewRepository(_multiClauseDetail),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Birincil kategori: ilk sırada olan (Temizlik).
      expect(find.text('Temizlik'), findsOneWidget);
      // İkincil kategoriler tag olarak görünmeli.
      expect(find.text('Yemek'), findsOneWidget);
      expect(find.text('Oda'), findsOneWidget);

      // Güven oranı: (0.9 + 0.7 + 0.8) / 3 = 0.8 -> %80.
      expect(find.text('%80'), findsOneWidget);

      // En olumsuz cümle öne çıkan şikayet olarak gösterilmeli.
      expect(
        find.text('"Banyo çok kirliydi ve havlular değiştirilmemişti."'),
        findsOneWidget,
      );

      // İki farklı öneri de listelenmeli.
      expect(
        find.textContaining('Temizlik departmanı oda çıkış'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Oda büyüklüğü beklentisi'),
        findsOneWidget,
      );

      // Cümle cümle analiz için buton gösterilmeli.
      expect(find.text('Detaylı Analiz'), findsOneWidget);
    });

    testWidgets('analiz yoksa özet kartı yerine boş durum gösterilir', (
      tester,
    ) async {
      final detail = ReviewDetail(
        id: 'r2',
        comment: 'Henüz analiz edilmemiş yorum.',
        rating: 4,
        reviewDate: DateTime(2026, 7, 22),
      );

      await tester.pumpApp(
        const ReviewDetailScreen(reviewId: 'r2'),
        overrides: [
          reviewRepositoryProvider.overrideWithValue(
            _StubReviewRepository(detail),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('AI analizi henüz yok'), findsOneWidget);
      expect(find.text('Detaylı Analiz'), findsNothing);
    });
  });

  group('ReviewDetailScreen manuel aksiyon ekleme', () {
    testWidgets('departman personeli buton görmez', (tester) async {
      await tester.pumpApp(
        const ReviewDetailScreen(reviewId: 'r1'),
        overrides: [
          reviewRepositoryProvider.overrideWithValue(
            _StubReviewRepository(_multiClauseDetail),
          ),
          authRepositoryProvider.overrideWithValue(
            StubAuthRepository(currentUser: testDepartmentUser),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Aksiyon Ekle'), findsNothing);
    });

    testWidgets(
      'admin butona basınca form açılır ve aksiyon ekler',
      (tester) async {
        await tester.pumpApp(
          const ReviewDetailScreen(reviewId: 'r1'),
          overrides: [
            reviewRepositoryProvider.overrideWithValue(
              _StubReviewRepository(_multiClauseDetail),
            ),
            authRepositoryProvider.overrideWithValue(
              StubAuthRepository(currentUser: testAdmin),
            ),
            actionItemRepositoryProvider.overrideWithValue(
              FakeActionItemRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Aksiyon Ekle'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, 'Aksiyon başlığı'), findsOneWidget);

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kat Hizmetleri & Temizlik').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Aksiyon başlığı'),
          'Bar servis noktası sayısı artırılsın',
        );
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.text('Aksiyon eklendi.'), findsOneWidget);
      },
    );

    testWidgets(
      'AI zaten bu yorum için aksiyon oluşturduysa form onun önerisi ve departmanıyla önceden dolu açılır',
      (tester) async {
        final existingActionItem = ActionItem(
          id: 'existing-1',
          title: 'Temizlik departmanı oda çıkış kontrol listesini gözden geçirmeli.',
          status: ActionStatus.open,
          departmentId: 'dept-cleaning',
          departmentName: 'Kat Hizmetleri & Temizlik',
          reviewId: 'r1',
        );

        await tester.pumpApp(
          const ReviewDetailScreen(reviewId: 'r1'),
          overrides: [
            reviewRepositoryProvider.overrideWithValue(
              _StubReviewRepository(_multiClauseDetail),
            ),
            authRepositoryProvider.overrideWithValue(
              StubAuthRepository(currentUser: testAdmin),
            ),
            actionItemRepositoryProvider.overrideWithValue(
              _StubActionItemRepository([existingActionItem]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Aksiyon Ekle').first);
        await tester.pumpAndSettle();

        // Başlık, AI'ın zaten oluşturduğu aksiyonun başlığıyla dolu.
        expect(
          find.widgetWithText(
            TextField,
            'Temizlik departmanı oda çıkış kontrol listesini gözden geçirmeli.',
          ),
          findsOneWidget,
        );
        // Departman da AI'ın seçtiği departmanla önceden seçili.
        expect(
          find.widgetWithText(
            DropdownButtonFormField<String>,
            'Kat Hizmetleri & Temizlik',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
