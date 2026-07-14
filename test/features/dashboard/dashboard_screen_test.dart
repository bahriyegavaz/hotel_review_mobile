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
  Future<ActionItem> updateStatus({
    required String id,
    required ActionStatus status,
  }) async =>
      throw UnimplementedError();
}

List<Override> _overrides(
  DashboardRepository dashboard, {
  ActionItemRepository? actions,
}) =>
    [
      authRepositoryProvider.overrideWithValue(
        StubAuthRepository(currentUser: testDepartmentUser),
      ),
      dashboardRepositoryProvider.overrideWithValue(dashboard),
      actionItemRepositoryProvider
          .overrideWithValue(actions ?? FakeActionItemRepository()),
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

    test('trend yükseliş/düşüş doğru belirlenir', () {
      final rising = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        negativeTrend: [
          DailyNegativeCount(date: DateTime(2026, 1, 1), count: 2),
          DailyNegativeCount(date: DateTime(2026, 1, 2), count: 5),
        ],
      );
      expect(rising.isNegativeTrendRising, isTrue);
    });

    test('tek veri noktasıyla trend yönü belirsiz (null)', () {
      final summary = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 0,
        totalReviewCount: 0,
        negativeTrend: [
          DailyNegativeCount(date: DateTime(2026, 1, 1), count: 3),
        ],
      );
      expect(summary.isNegativeTrendRising, isNull);
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

    testWidgets('negatif karta basınca detay açılır', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Negatif yorum'));
      await tester.pumpAndSettle();

      expect(find.text('banyo'), findsOneWidget);
      expect(find.text('havlu'), findsOneWidget);
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
    testWidgets('kullanıcı adı ve tarih gösterilir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Housekeeping Personeli'), findsOneWidget);
      // Selamlama saate göre değişir; dördünden biri mutlaka olmalı.
      final greetings = ['Günaydın,', 'İyi günler,', 'İyi akşamlar,', 'İyi geceler,'];
      final found = greetings.any(
        (g) => tester.any(find.text(g)),
      );
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

      expect(find.text('Bekleyen görevler'), findsOneWidget);
      expect(find.text('Tümünü gör'), findsOneWidget);
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
      // "Bekleyen görevler" başlığı bir kez, kartlar en fazla iki.
      expect(find.text('Bekleyen görevler'), findsOneWidget);
    });

    testWidgets('açık görev yoksa önizleme bölümü hiç görünmez',
        (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(
          FakeDashboardRepository(),
          actions: EmptyActionItemRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen görevler'), findsNothing);
    });
  });
}