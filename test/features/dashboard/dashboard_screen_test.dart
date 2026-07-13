import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/features/dashboard/data/fake_dashboard_repository.dart';
import 'package:hotel_review_mobile/features/dashboard/domain/dashboard_repository.dart';
import 'package:hotel_review_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:hotel_review_mobile/features/dashboard/presentation/dashboard_providers.dart';
import 'package:hotel_review_mobile/features/dashboard/presentation/dashboard_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

/// Her zaman hata fırlatan repository - hata ekranını test etmek için.
class FailingDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async {
    throw const DashboardNetworkFailure();
  }
}

/// Dashboard ekranını, oturumu açık bir departman kullanıcısıyla kurar.
List<Override> _overrides(DashboardRepository repository) => [
      authRepositoryProvider.overrideWithValue(
        StubAuthRepository(currentUser: testDepartmentUser),
      ),
      dashboardRepositoryProvider.overrideWithValue(repository),
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

    test('eşik değeri: %20 üstü uyarı verir, tam %20 vermez', () {
      const justAbove = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 21,
        totalReviewCount: 100,
      );
      const exactlyTwenty = DashboardSummary(
        todayReviewCount: 0,
        openActionCount: 0,
        negativeReviewCount: 20,
        totalReviewCount: 100,
      );

      expect(justAbove.hasHighNegativeRatio, isTrue);
      // hasHighNegativeRatio => negativeRatio > 20 (>= değil).
      // Bilinçli bir karar; bu test onu kilitliyor.
      expect(exactlyTwenty.hasHighNegativeRatio, isFalse);
    });
  });

  group('DashboardScreen', () {
    testWidgets('yüklenirken spinner gösterir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );

      expect(find.text('Özet yükleniyor...'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Özet yükleniyor...'), findsNothing);
    });

    testWidgets('KPI kartları doğru değerleri gösterir', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bugünkü yorum'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Açık görev'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4.1'), findsOneWidget);
    });

    testWidgets('negatif oran yüksekse uyarı rozeti çıkar', (tester) async {
      // Fake varsayılanı 12/50 = %24, eşik %20 -> uyarı beklenir.
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FakeDashboardRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('eşik değerin üzerinde'), findsOneWidget);
    });

    testWidgets('negatif oran düşükse uyarı çıkmaz', (tester) async {
      final repository = FakeDashboardRepository(
        summary: const DashboardSummary(
          todayReviewCount: 3,
          openActionCount: 1,
          negativeReviewCount: 2,
          totalReviewCount: 50, // %4
          averageRating: 4.8,
        ),
      );

      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('eşik değerin üzerinde'), findsNothing);
    });

    testWidgets('ortalama puan yoksa tire gösterir', (tester) async {
      final repository = FakeDashboardRepository(
        summary: DashboardSummary.empty,
      );

      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();

      // 0.0 değil, tire. "Veri yok" ile "puan sıfır" farklı şeyler.
      expect(find.text('-'), findsOneWidget);
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

    testWidgets('özet yüklenemese bile navigasyon çalışır', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: _overrides(FailingDashboardRepository()),
      );
      await tester.pumpAndSettle();

      // Bir bileşenin hatası tüm ekranı öldürmemeli.
      expect(find.textContaining('Housekeeping Personeli'), findsOneWidget);
      expect(find.text('Görevlerim'), findsOneWidget);
    });
  });
}