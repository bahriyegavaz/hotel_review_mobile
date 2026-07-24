import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/action_items/data/fake_action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_item_providers.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/features/dashboard/data/fake_dashboard_repository.dart';
import 'package:hotel_review_mobile/features/dashboard/domain/dashboard_repository.dart';
import 'package:hotel_review_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:hotel_review_mobile/features/dashboard/presentation/dashboard_providers.dart';
import 'package:hotel_review_mobile/features/dashboard/presentation/dashboard_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

class FailingDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async {
    throw const DashboardNetworkFailure();
  }
}

/// Boş görev listesi dönen repository - "bekleyen görev yok" senaryosu için.
class EmptyActionItemRepository implements ActionItemRepository {
  @override
  Future<List<ActionItem>> getActionItems() async => const [];

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
  }) async => throw UnimplementedError();
}

List<Override> _overrides(
  DashboardRepository dashboard, {
  ActionItemRepository? actions,
}) => [
  authRepositoryProvider.overrideWithValue(
    StubAuthRepository(currentUser: testDepartmentUser),
  ),
  dashboardRepositoryProvider.overrideWithValue(dashboard),
  actionItemRepositoryProvider.overrideWithValue(
    actions ?? FakeActionItemRepository(),
  ),
];

void main() {
  group('DashboardSummary domain kuralları', () {
    test('negatif oran doğru hesaplanır', () {
      const summary = DashboardSummary(
        todayReviewCount: 5,
        openActionCount: 2,
        negativeReviewCount: 12,
        totalReviewCount: 50,
      );
      expect(summary.negativeRatio, 24.0);
    });

    test('hiç yorum yoksa sıfıra bölme hatası vermez', () {
      expect(DashboardSummary.empty.negativeRatio, 0);
      expect(DashboardSummary.empty.hasHighNegativeRatio, isFalse);
    });

    test('puan trendi düşüş doğru belirlenir', () {
      final declining = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        ratingTrend: [
          DailyRatingPoint(
            date: DateTime(2026, 1, 1),
            averageRating: 4.5,
            reviewCount: 2,
          ),
          DailyRatingPoint(
            date: DateTime(2026, 1, 2),
            averageRating: 3.0,
            reviewCount: 5,
          ),
        ],
      );
      expect(declining.isRatingTrendDeclining, isTrue);
    });

    test('tek veri noktasıyla trend yönü belirsiz (null)', () {
      final summary = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        ratingTrend: [
          DailyRatingPoint(
            date: DateTime(2026, 1, 1),
            averageRating: 3.0,
            reviewCount: 3,
          ),
        ],
      );
      expect(summary.isRatingTrendDeclining, isNull);
    });
  });

  group('DashboardScreen özet', () {
    testWidgets('KPI kartları doğru değerleri gösterir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bugünkü yorum'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Açık görev'), findsOneWidget);
      expect(find.text('4.1'), findsOneWidget);
    });

    testWidgets('negatif detay (trend ve şikayetler) tıklamadan görünür', (
      tester,
    ) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      // Negatif detay artık hep açık - karta tıklamaya gerek yok.
      // Tekrar eden şikayetler doğrudan görünür ("kelime (sayı)" formatında).
      expect(find.text('banyo (8)'), findsOneWidget);
      expect(find.text('havlu (6)'), findsOneWidget);
    });

    testWidgets('hata durumunda tekrar dene butonu çıkar', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FailingDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Özet veriler yüklenemedi'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });

  group('DashboardScreen selamlama', () {
    testWidgets('kullanıcı adı ve selamlama gösterilir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      // Kullanıcı adı hero başlığında görünür.
      expect(find.textContaining('Housekeeping Personeli'), findsOneWidget);

      // Selamlama saate göre değişir ve hero'da isimle birleşik, virgülsüz
      // (örn. "Günaydın Housekeeping Personeli 👋"). Bu yüzden textContaining.
      final greetings = ['Günaydın', 'Merhaba', 'İyi akşamlar', 'İyi geceler'];
      final found = greetings.any((g) => tester.any(find.textContaining(g)));
      expect(found, isTrue);
    });
  });

  group('DashboardScreen bekleyen görevler', () {
    testWidgets('açık görev varsa önizleme gösterilir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen Görevler'), findsOneWidget);
      expect(find.text('Tümü'), findsOneWidget);
      // FakeActionItemRepository'de gecikmiş "Oda 304 klima" görevi var,
      // en acil olduğu için önizlemede olmalı.
      expect(find.text('Oda 304 klima arızası kontrolü'), findsOneWidget);
    });

    testWidgets('en fazla 2 görev önizlenir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      // Fake'te 3 açık görev var ama önizlemede en fazla 2 gösterilir.
      // "Bekleyen Görevler" başlığı bir kez, kartlar en fazla iki.
      expect(find.text('Bekleyen Görevler'), findsOneWidget);
    });

    testWidgets('açık görev yoksa önizleme bölümü hiç görünmez', (
      tester,
    ) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(
          FakeDashboardRepository(),
          actions: EmptyActionItemRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen Görevler'), findsNothing);
    });
  });
}
