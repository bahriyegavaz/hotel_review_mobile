import '../domain/action_item.dart';
import '../domain/action_item_repository.dart';

/// Backend hazır olmadan aksiyon ekranını geliştirmek için.
/// Demo verisi rapordaki senaryolara uygun: negatif yorumlardan doğan görevler.
///
/// Kullanıcı id'si '3' (temizlik@hotel.com) bazı görevlere atanmış -
/// "Bana atananlar" filtresini test edebilmek için.
class FakeActionItemRepository implements ActionItemRepository {
  FakeActionItemRepository() {
    _items = [
      ActionItem(
        id: '1',
        title: 'Banyo kontrol checklisti güncellensin',
        status: ActionStatus.open,
        departmentId: '10',
        departmentName: 'Kat Hizmetleri & Temizlik',
        reviewId: '101',
        assignedToId: '3',
        assignedToName: 'Housekeeping Personeli',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        reviewComment: 'Banyoda kötü bir koku vardı, havlular kirliydi.',
        suggestion:
            'Housekeeping departmanı oda çıkış kontrol listesine banyo ve '
            'havlu kontrolünü eklemeli.',
      ),
      ActionItem(
        id: '2',
        title: 'Oda 304 klima arızası kontrolü',
        status: ActionStatus.inProgress,
        departmentId: '10',
        departmentName: 'Kat Hizmetleri & Temizlik',
        reviewId: '102',
        assignedToId: '3',
        assignedToName: 'Housekeeping Personeli',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        reviewComment: 'Klima gece boyunca çalışmadı, oda çok sıcaktı.',
      ),
      ActionItem(
        id: '3',
        title: 'Havlu stoğu yenilensin',
        status: ActionStatus.open,
        departmentId: '10',
        departmentName: 'Kat Hizmetleri & Temizlik',
        reviewId: '103',
        // Atanmamış görev - "Atanmamış" etiketini test etmek için.
        dueDate: DateTime.now().add(const Duration(days: 5)),
        reviewComment: 'Havlular eski ve yıpranmış görünüyordu.',
      ),
      ActionItem(
        id: '4',
        title: 'Kahvaltı büfesi çeşitliliği artırılsın',
        status: ActionStatus.resolved,
        departmentId: '10',
        departmentName: 'Kat Hizmetleri & Temizlik',
        reviewId: '104',
        assignedToId: '2',
        assignedToName: 'Demo Müdür',
        reviewComment: 'Kahvaltıda çeşit azdı.',
      ),
      ActionItem(
        id: '5',
        title: 'Kahvaltı büfesi ekipman kontrolü',
        status: ActionStatus.open,
        departmentId: '20',
        departmentName: 'Mutfak & F&B',
        assignedToName: 'Mutfak Ekibi',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        reviewComment: 'Kahvaltıda sıcak yemekler soğuktu.',
        suggestion: 'Benmari ısıtıcıları kontrol edilmeli.',
      ),
      ActionItem(
        id: '6',
        title: 'Menü alerjen etiketleri güncellensin',
        status: ActionStatus.inProgress,
        departmentId: '20',
        departmentName: 'Mutfak & F&B',
        assignedToName: 'Mutfak Ekibi',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        suggestion: 'Alerjen bilgisi eksik ürünler işaretlenmeli.',
      ),
    ];
  }

  late final List<ActionItem> _items;

  @override
  Future<List<ActionItem>> getActionItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const UnknownActionItemFailure('Aksiyon bulunamadı.');
    }

    _items[index] = _items[index].copyWithStatus(status);
  }

  @override
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const UnknownActionItemFailure('Aksiyon bulunamadı.');
    }

    _items[index] = _items[index].copyWithDepartment(
      departmentId: departmentId,
      departmentName: departmentName,
    );
  }

  @override
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final created = ActionItem(
      id: 'manual-${_items.length + 1}',
      title: title,
      status: ActionStatus.open,
      departmentId: departmentId,
      departmentName: departmentName,
      reviewId: reviewId,
      dueDate: dueDate,
    );
    _items.add(created);
    return created;
  }
}
