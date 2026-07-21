import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/action_item.dart';
import '../domain/action_item_repository.dart';
import 'action_item_providers.dart';

/// Aksiyon listesini yükler ve durum güncellemelerini yönetir.
///
/// AsyncNotifier kullanıyoruz çünkü liste yükleme doğal olarak asenkron ve
/// üç durumu var: loading, data, error. Bunları elle yazmak yerine
/// AsyncValue'ya bırakıyoruz.
class ActionItemsController extends AsyncNotifier<List<ActionItem>> {
  ActionItemRepository get _repository =>
      ref.read(actionItemRepositoryProvider);

  @override
  Future<List<ActionItem>> build() => _repository.getActionItems();

  /// Pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getActionItems);
  }

  /// Durum güncelleme - optimistic update ile.
  ///
  /// Kullanıcı "Tamamlandı"ya basınca sunucuyu beklemeden listeyi güncelliyoruz;
  /// istek başarısız olursa eski hale döndürüyoruz. Böylece saha personeli
  /// zayıf bağlantıda bile akıcı bir deneyim yaşar.
  ///
  /// Dönüş: null = başarılı, dolu string = gösterilecek hata mesajı.
  Future<String?> updateStatus(String id, ActionStatus newStatus) async {
    // Riverpod 3.0'da AsyncValue.valueOrNull kaldırıldı, yerine `value` geldi.
    final previous = state.value;
    if (previous == null) return null;

    // 1. Önce ekranı güncelle.
    state = AsyncValue.data([
      for (final item in previous)
        if (item.id == id) item.copyWithStatus(newStatus) else item,
    ]);

    // 2. Sunucuya gönder.
    try {
      final updated = await _repository.updateStatus(id: id, status: newStatus);
      // 3. Sunucunun döndürdüğü gerçek kayıtla değiştir.
      state = AsyncValue.data([
        for (final item in state.value ?? previous)
          if (item.id == id) updated else item,
      ]);
      return null;
    } on ActionItemFailure catch (e) {
      // 4. Hata: eski listeye dön, hatayı ekrana bildir.
      state = AsyncValue.data(previous);
      return e.message;
    } catch (_) {
      state = AsyncValue.data(previous);
      return 'Beklenmeyen bir hata oluştu.';
    }
  }
}

final actionItemsControllerProvider =
    AsyncNotifierProvider<ActionItemsController, List<ActionItem>>(
  ActionItemsController.new,
);

/// Filtre uygulanmış liste. Ekran bunu izler.
///
/// Filtreleme mantığı controller'da değil burada - çünkü bu bir "türetilmiş
/// veri", state değil. Filtre değişince liste sunucudan tekrar çekilmez,
/// sadece süzülür.
///
/// İki katmanlı süzme:
///   1. ROL: departmentUser sadece kendi departmanının görevlerini görür.
///      Admin/Manager her şeyi görür. (Gerçekte backend JWT'den filtreler;
///      fake ile çalışırken bu satır aynı davranışı simüle eder ve backend
///      bir gün eksik filtrelese bile ikinci bir güvence olur.)
///   2. CHIP: kullanıcının seçtiği filtre (Tümü / Bana atananlar / Açık).
final filteredActionItemsProvider =
    Provider<AsyncValue<List<ActionItem>>>((ref) {
  final itemsAsync = ref.watch(actionItemsControllerProvider);
  final filter = ref.watch(actionFilterProvider);
  final currentUser = ref.watch(currentUserProvider);

  return itemsAsync.whenData((items) {
    // 1. Rol süzmesi: departman personeli sadece kendi departmanını görür.
    final visibleItems = (currentUser != null &&
            currentUser.role == UserRole.departmentUser &&
            currentUser.departmentId != null)
        ? items
            .where((i) => i.departmentId == currentUser.departmentId)
            .toList()
        : items;

    // 2. Chip süzmesi.
    final filtered = switch (filter) {
      ActionFilter.all => visibleItems,
      ActionFilter.assignedToMe =>
        visibleItems.where((i) => i.isAssignedTo(currentUser?.id)).toList(),
      ActionFilter.open =>
        visibleItems.where((i) => !i.status.isClosed).toList(),
    };

    // Gecikmiş görevler üstte, sonra açık olanlar, en altta kapalılar.
    final sorted = [...filtered]..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        if (a.status.isClosed != b.status.isClosed) {
          return a.status.isClosed ? 1 : -1;
        }
        return 0;
      });
    return sorted;
  });
});