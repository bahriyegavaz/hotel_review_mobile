import 'action_item.dart';

sealed class ActionItemFailure implements Exception {
  const ActionItemFailure(this.message);
  final String message;
}

class ActionItemNetworkFailure extends ActionItemFailure {
  const ActionItemNetworkFailure()
      : super('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
}

class ActionItemForbiddenFailure extends ActionItemFailure {
  const ActionItemForbiddenFailure()
      : super('Bu görevi güncelleme yetkiniz yok.');
}

class UnknownActionItemFailure extends ActionItemFailure {
  const UnknownActionItemFailure([String? message])
      : super(message ?? 'Beklenmeyen bir hata oluştu.');
}

abstract class ActionItemRepository {
  /// GET /api/action-items
  ///
  /// Filtreleme backend'in işi: JWT'deki role ve department_id'ye bakıp
  /// kullanıcının görmesi gereken kayıtları döner. Mobil "bana şu departmanı
  /// ver" demez - dese kullanıcı isteği değiştirip başkasının verisini çekerdi.
  Future<List<ActionItem>> getActionItems();

  /// PATCH /api/action-items/{id}/status
  Future<ActionItem> updateStatus({
    required String id,
    required ActionStatus status,
  });
}