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
  ///
  /// Backend bu endpoint'te güncellenmiş nesneyi geri döndürmüyor (sadece
  /// `{success, message}` - data hep null). O yüzden burada bir ActionItem
  /// dönmüyoruz; başarılıysa çağıran taraf zaten uyguladığı optimistic
  /// güncellemeyi (bkz. ActionItemsController) kalıcı sayar.
  Future<void> updateStatus({required String id, required ActionStatus status});

  /// PATCH /api/action-items/{id}/department — Admin/Manager, AI'ın
  /// önerdiği departmanı yanlışsa düzeltir. Kişi bazlı değil departman
  /// bazlı: atama Angular panelinin işi olarak kalıyor (bkz. ActionItem).
  ///
  /// NOT: Backend'de bu endpoint henüz yok (şu an sadece durum güncelleme
  /// var). Bu, mobil UI'ın beklediği sözleşmeyi tanımlıyor; backend tarafı
  /// hazır olunca gerçek departman değişikliği çalışacak, mobilde ek
  /// değişiklik gerekmeyecek. Diğer PATCH endpoint'leri gibi bunun da
  /// güncellenmiş nesneyi dönmeyeceğini varsayıyoruz (bkz. updateStatus).
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  });

  /// POST /api/action-items — Admin/Manager bir yoruma manuel aksiyon ekler.
  ///
  /// Backend'de bu endpoint zaten var ve çalışıyor ("Web Panel (Angular)"
  /// etiketli olsa da erişim kontrolü role bazlı [Admin,Manager] - istemciye
  /// bakmıyor, bu yüzden mobil de kullanabiliyor. Kişi bazlı gitmediğimiz
  /// için assignedTo alanını hiç göndermiyoruz.
  ///
  /// Backend sadece oluşturulan kaydın id'sini döner (departman adı gibi
  /// diğer alanları echo etmiyor) - dönen ActionItem, zaten bildiğimiz
  /// parametrelerden (departmentName dahil) + backend'in verdiği id'den
  /// yerelde oluşturuluyor.
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  });
}
