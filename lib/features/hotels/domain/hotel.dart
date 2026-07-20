/// Personelin çalıştığı otel/restoran.
///
/// Bir personel birden fazla otelde çalışabilir. Giriş sonrası hangi otelin
/// verisine bakacağını seçer, drawer'dan değiştirebilir.
///
/// NOT: Rapor bölüm 7'deki veri modelinde `hotels` tablosu YOK.
/// Backend tarafında eklenmesi gerekiyor:
///   - hotels tablosu
///   - users <-> hotels ilişkisi (bir kullanıcı birden çok otele bağlı)
///   - reviews/action_items/departments tablolarında hotel_id
///   - Login response'unda ya da /my-hotels endpoint'inde kullanıcının otelleri
class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    this.city,
  });

  final String id;
  final String name;
  final String? city;

  /// Drawer ve seçim ekranında: "Grand Hotel - Antalya"
  String get displayName => city == null ? name : '$name - $city';

  @override
  bool operator ==(Object other) =>
      other is Hotel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}