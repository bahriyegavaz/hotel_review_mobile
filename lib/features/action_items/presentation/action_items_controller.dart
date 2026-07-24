import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // 2. Sunucuya gönder. Backend güncellenmiş nesneyi dönmüyor (bkz.
    // ActionItemRepository.updateStatus) - başarılıysa 1. adımdaki
    // optimistic güncelleme zaten kalıcı sonuç sayılır.
    try {
      await _repository.updateStatus(id: id, status: newStatus);
      return null;
    } on ActionItemFailure catch (e) {
      // 3. Hata: eski listeye dön, hatayı ekrana bildir.
      state = AsyncValue.data(previous);
      return e.message;
    } catch (_) {
      state = AsyncValue.data(previous);
      return 'Beklenmeyen bir hata oluştu.';
    }
  }

  /// AI'ın önerdiği departmanı düzelt (Admin/Manager). updateStatus ile
  /// aynı desen: optimistic update, hata olursa eski hale dön.
  ///
  /// Dönüş: null = başarılı, dolu string = gösterilecek hata mesajı.
  Future<String?> reassignDepartment(
    String id,
    String departmentId,
    String departmentName,
  ) async {
    final previous = state.value;
    if (previous == null) return null;

    state = AsyncValue.data([
      for (final item in previous)
        if (item.id == id)
          item.copyWithDepartment(
            departmentId: departmentId,
            departmentName: departmentName,
          )
        else
          item,
    ]);

    try {
      await _repository.reassignDepartment(
        id: id,
        departmentId: departmentId,
        departmentName: departmentName,
      );
      return null;
    } on ActionItemFailure catch (e) {
      state = AsyncValue.data(previous);
      return e.message;
    } catch (_) {
      state = AsyncValue.data(previous);
      return 'Beklenmeyen bir hata oluştu.';
    }
  }

  /// Admin/Manager bir yoruma manuel aksiyon ekler (bkz.
  /// ActionItemRepository.createManualActionItem). Optimistic değil -
  /// yeni kayıt sunucudan id alınana kadar listeye eklenmiyor.
  ///
  /// Dönüş: null = başarılı, dolu string = gösterilecek hata mesajı.
  Future<String?> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    final previous = state.value ?? [];

    try {
      final created = await _repository.createManualActionItem(
        reviewId: reviewId,
        departmentId: departmentId,
        departmentName: departmentName,
        title: title,
        dueDate: dueDate,
      );
      state = AsyncValue.data([...previous, created]);
      return null;
    } on ActionItemFailure catch (e) {
      return e.message;
    } catch (_) {
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
///   2. ADMIN/MANAGER: üstteki departman seçici (Tümü / departman adı).
///      DEPARTMAN PERSONELİ: chip (Atanan / Açık) - zaten sadece kendi
///      departmanını gördüğü için "Tümü" onlar için ayrı bir anlam taşımıyor.
final filteredActionItemsProvider = Provider<AsyncValue<List<ActionItem>>>((
  ref,
) {
  final itemsAsync = ref.watch(actionItemsControllerProvider);
  final filter = ref.watch(actionFilterProvider);
  final selectedDepartmentId = ref.watch(departmentFilterProvider);
  final currentUser = ref.watch(currentUserProvider);

  return itemsAsync.whenData((items) {
    final canViewAllDepartments = currentUser?.canViewAllDepartments ?? false;

    // 1. Rol süzmesi: departman/saha personeli sadece kendi departmanını görür.
    final visibleItems =
        (currentUser != null &&
            currentUser.isDepartmentScoped &&
            currentUser.departmentId != null)
        ? items
              .where((i) => i.departmentId == currentUser.departmentId)
              .toList()
        : items;

    // 2. Admin/Manager: departman seçici. Departman personeli: chip.
    final filtered = canViewAllDepartments
        ? (selectedDepartmentId == null
              ? visibleItems
              : visibleItems
                    .where((i) => i.departmentId == selectedDepartmentId)
                    .toList())
        : switch (filter) {
            ActionFilter.all => visibleItems,
            ActionFilter.assignedToMe => visibleItems
                .where((i) => i.isAssignedTo(currentUser?.id))
                .toList(),
            ActionFilter.open =>
              visibleItems.where((i) => !i.status.isClosed).toList(),
          };

    // Gecikmiş görevler üstte, sonra açık olanlar, en altta kapalılar.
    final sorted = [...filtered]
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        if (a.status.isClosed != b.status.isClosed) {
          return a.status.isClosed ? 1 : -1;
        }
        return 0;
      });
    return sorted;
  });
});

/// Admin/Manager için üstte gösterilecek departman listesi - ayrı bir API
/// çağrısı yapmadan, zaten yüklenmiş görevlerden türetilir (id, ad).
final availableDepartmentsProvider = Provider<List<(String id, String name)>>((
  ref,
) {
  final items = ref.watch(actionItemsControllerProvider).value ?? const [];
  final map = <String, String>{};
  for (final item in items) {
    final name = item.departmentName?.trim();
    map[item.departmentId] = (name == null || name.isEmpty)
        ? 'Departmansız'
        : name;
  }
  final entries = map.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return [for (final e in entries) (e.key, e.value)];
});
