import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/action_items/data/fake_action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item_repository.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_item_providers.dart';
import 'package:hotel_review_mobile/features/action_items/presentation/action_items_screen.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/core/widget/loading_skeleton.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review.dart';
import 'package:hotel_review_mobile/features/reviews/domain/review_repository.dart';
import 'package:hotel_review_mobile/features/reviews/presentation/review_providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

/// Görev kartı artık review'ın AI önerisini göstermek için
/// reviewDetailProvider'ı da izliyor. Gerçek FakeReviewRepository'nin
/// 400ms gecikmesini beklemek yerine (ve pending-timer hatalarından
/// kaçınmak için) anlık dönen bir stub kullanıyoruz - bu ekranın testleri
/// review verisiyle değil action item verisiyle ilgileniyor.
class _InstantReviewRepository implements ReviewRepository {
  @override
  Future<Review> createReview(NewReview review) => throw UnimplementedError();

  @override
  Future<List<Review>> getMyReviews() async => const [];

  @override
  Future<ReviewDetail> getReviewDetail(String id) async {
    return ReviewDetail(
      id: id,
      comment: '',
      rating: 0,
      reviewDate: DateTime(2026),
    );
  }
}

/// FakeActionItemRepository'deki id '1' görevinin doğrudan `suggestion`
/// alanı var - kart artık ham başlık yerine bunu gösteriyor.
const _housekeepingSuggestion =
    'Housekeeping departmanı oda çıkış kontrol listesine banyo ve '
    'havlu kontrolünü eklemeli.';

/// Her zaman hata fırlatan repository - hata ekranını test etmek için.
class FailingActionItemRepository implements ActionItemRepository {
  @override
  Future<List<ActionItem>> getActionItems() async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  }) async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    throw const ActionItemNetworkFailure();
  }
}

/// Boş liste dönen repository.
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

/// Görev listesi ekranını, oturumu açık bir departman kullanıcısıyla açar.
/// FakeActionItemRepository'deki görevlerin ikisi id '3'e atalı.
List<Override> _overrides(ActionItemRepository repository) => [
  authRepositoryProvider.overrideWithValue(
    StubAuthRepository(currentUser: testDepartmentUser),
  ),
  actionItemRepositoryProvider.overrideWithValue(repository),
  reviewRepositoryProvider.overrideWithValue(_InstantReviewRepository()),
];

/// Aynı ekranı Admin oturumuyla açar - departman seçici ve atama
/// özelliklerini test etmek için (departman personeli bunları göremez).
List<Override> _adminOverrides(ActionItemRepository repository) => [
  authRepositoryProvider.overrideWithValue(
    StubAuthRepository(currentUser: testAdmin),
  ),
  actionItemRepositoryProvider.overrideWithValue(repository),
  reviewRepositoryProvider.overrideWithValue(_InstantReviewRepository()),
];

void main() {
  group('ActionItemsScreen liste görüntüleme', () {
    testWidgets('yüklenirken spinner gösterir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );

      // pumpAndSettle çağırmıyoruz - henüz yükleniyor durumundayız.
      expect(find.byType(ListSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(ListSkeleton), findsNothing);
    });

    testWidgets('görevler yüklendiğinde kartlar listelenir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      // id '1'in doğrudan bir AI önerisi var - kart başlık yerine onu gösterir.
      expect(find.text(_housekeepingSuggestion), findsOneWidget);
      expect(find.text('Havlu stoğu yenilensin'), findsOneWidget);
    });

    testWidgets(
      'atanmamış görevde kişi etiketi hiç gösterilmez (sadeleştirme)',
      (tester) async {
        await tester.pumpApp(
          const ActionItemsScreen(),
          overrides: _overrides(FakeActionItemRepository()),
        );
        await tester.pumpAndSettle();

        // "Atanmamış" varsayılan bir durum - göstermek gürültü yaratıyor,
        // sadece gerçekten biri atanmışsa kişi etiketi gösteriliyor.
        expect(find.text('Atanmamış'), findsNothing);
        expect(find.text('Housekeeping Personeli'), findsWidgets);
      },
    );

    testWidgets('liste boşsa boş durum mesajı gösterir', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(EmptyActionItemRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aksiyon yok'), findsOneWidget);
    });

    testWidgets('yükleme hatasında hata ekranı ve tekrar dene butonu çıkar', (
      tester,
    ) async {
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
    testWidgets(
      '"Atanan" sadece kullanıcıya atalı görevleri gösterir',
      (tester) async {
        await tester.pumpApp(
          const ActionItemsScreen(),
          overrides: _overrides(FakeActionItemRepository()),
        );
        await tester.pumpAndSettle();

        // Başlangıçta 4 görev var, biri atanmamış.
        expect(find.text('Havlu stoğu yenilensin'), findsOneWidget);

        await tester.tap(find.text('Atanan'));
        await tester.pumpAndSettle();

        // id '3'e atalı iki görev kalmalı.
        expect(find.text(_housekeepingSuggestion), findsOneWidget);
        expect(find.text('Oda 304 klima arızası kontrolü'), findsOneWidget);
        // Atanmamış ve başkasına atalı görevler gizlenmeli.
        expect(find.text('Havlu stoğu yenilensin'), findsNothing);
        expect(
          find.text('Kahvaltı büfesi çeşitliliği artırılsın'),
          findsNothing,
        );
      },
    );

    testWidgets('"Açık" filtresi kapalı görevleri gizler', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      // "Kahvaltı büfesi" görevi resolved durumda.
      expect(
        find.text('Kahvaltı büfesi çeşitliliği artırılsın'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Açık'));
      await tester.pumpAndSettle();

      expect(find.text('Kahvaltı büfesi çeşitliliği artırılsın'), findsNothing);
      expect(find.text(_housekeepingSuggestion), findsOneWidget);
    });
  });

  group('ActionItemsScreen durum güncelleme', () {
    testWidgets('karta dokununca durum seçici açılır', (tester) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(_housekeepingSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Durumu güncelle'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Tamamlandı'), findsOneWidget);
    });

    testWidgets('durum seçilince kart güncellenir ve onay gösterilir', (
      tester,
    ) async {
      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _overrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(_housekeepingSuggestion));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Tamamlandı'));
      await tester.pumpAndSettle();

      expect(find.text('Durum güncellendi.'), findsOneWidget);
    });

    testWidgets('güncelleme başarısız olursa eski duruma dönülür', (
      tester,
    ) async {
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

  group('ActionItemsScreen admin/manager', () {
    testWidgets(
      'departman personelindeki Atanan/Açık chip\'leri yerine departman seçici gösterilir',
      (tester) async {
        await tester.pumpApp(
          const ActionItemsScreen(),
          overrides: _adminOverrides(FakeActionItemRepository()),
        );
        await tester.pumpAndSettle();

        // Departman seçici: "Tümü" + görevlerden türetilen departman adları.
        expect(find.widgetWithText(ChoiceChip, 'Tümü'), findsOneWidget);
        expect(
          find.widgetWithText(ChoiceChip, 'Kat Hizmetleri & Temizlik'),
          findsOneWidget,
        );
        expect(find.widgetWithText(ChoiceChip, 'Mutfak & F&B'), findsOneWidget);
        // Departman personeline özel chip'ler burada olmamalı.
        expect(find.widgetWithText(ChoiceChip, 'Atanan'), findsNothing);
      },
    );

    testWidgets('departman seçilince sadece o departmanın görevleri kalır', (
      tester,
    ) async {
      // Her iki departmanın da kartları (toplam 6 kart) tek seferde
      // görünsün diye viewport'u büyütüyoruz - aksi halde ListView.builder
      // ikinci grubu (viewport dışında kalan) hiç oluşturmaz.
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpApp(
        const ActionItemsScreen(),
        overrides: _adminOverrides(FakeActionItemRepository()),
      );
      await tester.pumpAndSettle();

      // Başlangıçta (Tümü) her iki departmandan görev var. id '5'in
      // doğrudan bir AI önerisi var - kart başlık yerine onu gösterir.
      const kitchenSuggestion = 'Benmari ısıtıcıları kontrol edilmeli.';
      expect(find.text(kitchenSuggestion), findsOneWidget);

      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Kat Hizmetleri & Temizlik'),
      );
      await tester.pumpAndSettle();

      // Mutfak & F&B departmanının görevi artık görünmemeli.
      expect(find.text(kitchenSuggestion), findsNothing);
      expect(find.text(_housekeepingSuggestion), findsOneWidget);
    });

    testWidgets(
      'departman etiketine dokununca departman değiştirme sheet\'i açılır ve günceller',
      (tester) async {
        await tester.pumpApp(
          const ActionItemsScreen(),
          overrides: _adminOverrides(FakeActionItemRepository()),
        );
        await tester.pumpAndSettle();

        // Kişi bazlı değil departman bazlı: her kartta departman etiketi var,
        // admin/manager için tıklanabilir (apartman ikonlu InkWell).
        final deptTagFinder = find.ancestor(
          of: find.byIcon(Icons.apartment_outlined),
          matching: find.byType(InkWell),
        );
        expect(deptTagFinder, findsWidgets);

        await tester.tap(deptTagFinder.first);
        await tester.pumpAndSettle();

        expect(find.text('Departmanı değiştir'), findsOneWidget);
        expect(
          find.widgetWithText(ListTile, 'Mutfak & F&B'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(ListTile, 'Mutfak & F&B'));
        // FakeActionItemRepository.reassignDepartment 500ms gecikmeli -
        // bottom sheet'in kapanış animasyonu bunu her zaman karşılamayabiliyor;
        // gecikmeyi garanti aşacak şekilde önce elle ileri sarıyoruz.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.text('Departman güncellendi.'), findsOneWidget);
      },
    );
  });

  group('ActionItemsScreen manuel oluşturulan görev başlığı', () {
    testWidgets(
      'title hiçbir cümleyle eşleşmiyorsa alakasız bir öneriye düşmez',
      (tester) async {
        // "Aksiyon Ekle" ile manuel oluşturulan görevlerde title zaten AI
        // önerisinin kendisi - review'ın ham cümlelerinden hiçbiriyle
        // birebir eşleşmez. Kart, eşleşme bulamayınca "en olumsuz cümle"ye
        // düşüp alakasız bir öneri göstermemeli; item.title'ı olduğu gibi
        // göstermeli.
        const manualItem = ActionItem(
          id: 'manual-1',
          title: 'Housekeeping banyo/havlu kontrol listesini güncellemeli.',
          status: ActionStatus.open,
          departmentId: '10',
          departmentName: 'Kat Hizmetleri & Temizlik',
          reviewId: 'r-unrelated',
        );

        await tester.pumpApp(
          const ActionItemsScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              StubAuthRepository(currentUser: testDepartmentUser),
            ),
            actionItemRepositoryProvider.overrideWithValue(
              _SingleItemActionItemRepository(manualItem),
            ),
            reviewRepositoryProvider.overrideWithValue(
              _UnrelatedClauseReviewRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Kendi title'ı gösterilmeli.
        expect(
          find.text('Housekeeping banyo/havlu kontrol listesini güncellemeli.'),
          findsOneWidget,
        );
        // Review'ın alakasız cümlesinin önerisi HİÇ gösterilmemeli.
        expect(
          find.textContaining('Geri bildirim müşteri ilişkileri'),
          findsNothing,
        );
      },
    );
  });
}

/// Sadece tek bir görev dönen repository.
class _SingleItemActionItemRepository implements ActionItemRepository {
  _SingleItemActionItemRepository(this.item);

  final ActionItem item;

  @override
  Future<List<ActionItem>> getActionItems() async => [item];

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

/// Görevin title'ıyla EŞLEŞMEYEN bir cümle içeren yorum detayı döner -
/// "eşleşme bulunamadığında en olumsuz cümleye düşme" davranışını test
/// etmek için.
class _UnrelatedClauseReviewRepository implements ReviewRepository {
  @override
  Future<Review> createReview(NewReview review) => throw UnimplementedError();

  @override
  Future<List<Review>> getMyReviews() async => const [];

  @override
  Future<ReviewDetail> getReviewDetail(String id) async {
    return ReviewDetail(
      id: id,
      comment: 'Tamamen alakasız bir yorum.',
      rating: 1,
      reviewDate: DateTime(2026),
      clauseAnalyses: const [
        ReviewClauseAnalysis(
          clauseText: 'Tamamen alakasız ve çok olumsuz bir cümle.',
          sentiment: Sentiment.negative,
          sentimentScore: -0.9,
          priority: 'Bilgi',
          categoryName: 'Genel',
          confidence: 0.5,
          suggestion: 'Geri bildirim müşteri ilişkileri tarafından sınıflandırılıp yönlendirilmeli.',
        ),
      ],
    );
  }
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
  Future<void> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  }) async {
    throw const ActionItemNetworkFailure();
  }

  @override
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    throw const ActionItemNetworkFailure();
  }
}
