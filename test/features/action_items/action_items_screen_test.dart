import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/action_items/data/fake_action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_item_providers.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_items_screen.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

/// Her zaman hata fırlatan repository - hata ekranını test etmek için.
class FailingActionItemRepository implements ActionItemRepository {
  @override
  Future<List<ActionItem>> getActionItems() async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<ActionItem> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    throw const ActionItemNetworkFailure();
  }
}

/// Boş liste dönen repository.
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

/// Görev listesi ekranını, oturumu açık bir departman kullanıcısıyla açar.
/// FakeActionItemRepository'deki görevlerin ikisi id '3'e atalı.
List<Override> _overrides(ActionItemRepository repository) => [
      authRepositoryProvider
          .overrideWithValue(StubAuthRepository(currentUser: testDepartmentUser)),
      actionItemRepositoryProvider.overrideWithValue(repository),
    ];

void main() {
  group('ActionItemsScreen liste görüntüleme', () {
    testWidgets('yüklenirken spinner gösterir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );

      // pumpAndSettle çağırmıyoruz - henüz yükleniyor durumundayız.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('görevler yüklendiğinde kartlar listelenir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Banyo kontrol checklisti güncellensin'),
        findsOneWidget,
      );
      expect(find.text('Havlu stoğu yenilensin'), findsOneWidget);
    });

    testWidgets('atanmamış görev "Atanmamış" olarak gösterilir',
        (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atanmamış'), findsOneWidget);
    });

    testWidgets('liste boşsa boş durum mesajı gösterir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(EmptyActionItemRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Görev bulunamadı.'), findsOneWidget);
    });

    testWidgets('yükleme hatasında hata ekranı ve tekrar dene butonu çıkar',
        (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FailingActionItemRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sunucuya ulaşılamadı'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });

  group('ActionItemsScreen filtreler', () {
    testWidgets('"Bana atananlar" sadece kullanıcıya atalı görevleri gösterir',
        (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      // Başlangıçta 4 görev var, biri atanmamış.
      expect(find.text('Havlu stoğu yenilensin'), findsOneWidget);

      await tester.tap(find.text('Bana atananlar'));
      await tester.pumpAndSettle();

      // id '3'e atalı iki görev kalmalı.
      expect(find.text('Banyo kontrol checklisti güncellensin'), findsOneWidget);
      expect(find.text('Oda 304 klima arızası kontrolü'), findsOneWidget);
      // Atanmamış ve başkasına atalı görevler gizlenmeli.
      expect(find.text('Havlu stoğu yenilensin'), findsNothing);
      expect(find.text('Kahvaltı büfesi çeşitliliği artırılsın'), findsNothing);
    });

    testWidgets('"Açık" filtresi kapalı görevleri gizler', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      // "Kahvaltı büfesi" görevi resolved durumda.
      expect(find.text('Kahvaltı büfesi çeşitliliği artırılsın'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Açık'));
      await tester.pumpAndSettle();

      expect(find.text('Kahvaltı büfesi çeşitliliği artırılsın'), findsNothing);
      expect(find.text('Banyo kontrol checklisti güncellensin'), findsOneWidget);
    });
  });

  group('ActionItemsScreen durum güncelleme', () {
    testWidgets('karta dokununca durum seçici açılır', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banyo kontrol checklisti güncellensin'));
      await tester.pumpAndSettle();

      expect(find.text('Durumu güncelle'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Tamamlandı'), findsOneWidget);
    });

    testWidgets('durum seçilince kart güncellenir ve onay gösterilir',
        (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banyo kontrol checklisti güncellensin'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Tamamlandı'));
      await tester.pumpAndSettle();

      expect(find.text('Durum güncellendi.'), findsOneWidget);
    });

    testWidgets('güncelleme başarısız olursa eski duruma dönülür',
        (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        // İlk yükleme başarılı, sonra güncelleme hata versin diye
        // FakeActionItemRepository yerine kendi hibrit stub'ımızı kullanabiliriz.
        // Basitlik için: FailingActionItemRepository yükleme aşamasında da
        // hata verdiği için burada _RejectingUpdateRepository kullanıyoruz.
        overrides: _overrides(_RejectingUpdateRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test görevi'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Tamamlandı'));
      await tester.pumpAndSettle();

      // Hata mesajı gösterilmeli ve rozet hâlâ "Açık" kalmalı.
      expect(find.textContaining('Sunucuya ulaşılamadı'), findsOneWidget);
      expect(find.text('Açık'), findsWidgets);
    });
  });
}

/// Listeyi başarıyla döner ama güncellemeyi reddeder.
/// Optimistic update'in geri alma (rollback) davranışını test etmek için.
class _RejectingUpdateRepository implements ActionItemRepository {
  @override
  Future<List<ActionItem>> getActionItems() async => [
        const ActionItem(
          id: '1',
          title: 'Test görevi',
          status: ActionStatus.open,
          departmentId: '10',
        ),
      ];

  @override
  Future<ActionItem> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    throw const ActionItemNetworkFailure();
  }
}