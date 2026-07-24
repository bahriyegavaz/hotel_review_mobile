import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/api_action_item_repository.dart';
import '../data/fake_action_item_repository.dart';
import '../domain/action_item_repository.dart';

/// Backend hazır olduğunda defaultValue'yu false yap.
/// Ya da: flutter run --dart-define=USE_FAKE_ACTION_ITEMS=false
const bool useFakeActionItems = bool.fromEnvironment(
  'USE_FAKE_ACTION_ITEMS',
  defaultValue: true,
);

final actionItemRepositoryProvider = Provider<ActionItemRepository>((ref) {
  if (useFakeActionItems) {
    return FakeActionItemRepository();
  }
  return ApiActionItemRepository(ref.watch(dioProvider));
});

/// Listenin üstündeki filtre çipleri.
///
/// Admin/Manager tüm departmanları görebildiği için bu çipler onlara
/// gösterilmiyor - onun yerine departman seçici (bkz. departmentFilterProvider)
/// kullanılıyor. Bu enum sadece departman personeli (kendi departmanına
/// sabitlenmiş kullanıcılar) için geçerli.
enum ActionFilter {
  all,
  assignedToMe,
  open;

  String get label => switch (this) {
    ActionFilter.all => 'Tümü',
    ActionFilter.assignedToMe => 'Atanan',
    ActionFilter.open => 'Açık',
  };

  /// Departman personeline gösterilen çipler - "Tümü" gösterilmiyor çünkü
  /// zaten sadece kendi departmanlarını görüyorlar, "Tümü" onlar için
  /// "Atanan"dan anlamlı bir şekilde ayrışmıyor.
  static const List<ActionFilter> departmentUserValues = [
    ActionFilter.assignedToMe,
    ActionFilter.open,
  ];
}

/// Seçili filtreyi tutar.
///
/// Riverpod 3.0'da StateProvider "legacy" sayılıyor ve ana API'den çıkarıldı
/// (kullanmak için `package:flutter_riverpod/legacy.dart` import etmek gerekir).
/// Bunun yerine önerilen yol: basit state için de Notifier kullanmak.
/// Birkaç satır fazla kod, ama state büyüdüğünde aynı desen çalışmaya devam eder.
class ActionFilterController extends Notifier<ActionFilter> {
  @override
  ActionFilter build() => ActionFilter.all;

  void select(ActionFilter filter) => state = filter;
}

final actionFilterProvider =
    NotifierProvider<ActionFilterController, ActionFilter>(
      ActionFilterController.new,
    );

/// Admin/Manager için üstteki departman seçici. `null` = "Tümü" (hepsi).
///
/// ActionFilterController ile aynı desen (bkz. yukarıdaki yorum) - basit
/// state için Notifier kullanıyoruz.
class DepartmentFilterController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? departmentId) => state = departmentId;
}

final departmentFilterProvider =
    NotifierProvider<DepartmentFilterController, String?>(
      DepartmentFilterController.new,
    );
