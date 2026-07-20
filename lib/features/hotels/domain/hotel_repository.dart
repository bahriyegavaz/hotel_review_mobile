import 'hotel.dart';

sealed class HotelFailure implements Exception {
  const HotelFailure(this.message);
  final String message;
}

class HotelNetworkFailure extends HotelFailure {
  const HotelNetworkFailure()
      : super('Otel listesi yüklenemedi. Bağlantınızı kontrol edin.');
}

class UnknownHotelFailure extends HotelFailure {
  const UnknownHotelFailure([String? message])
      : super(message ?? 'Beklenmeyen bir hata oluştu.');
}

abstract class HotelRepository {
  /// Giriş yapmış kullanıcının çalıştığı oteller.
  ///
  /// Backend bunu login response'unda ya da GET /api/my-hotels ile döner.
  /// JWT'den kullanıcıyı bulup ona bağlı otelleri getirir - yani bu istek
  /// AUTH GEREKTİRİR (login öncesi değil, sonrası).
  Future<List<Hotel>> getMyHotels();

  /// Seçili oteli cihazda saklar - uygulama tekrar açılınca sorulmasın.
  Future<void> saveSelectedHotel(Hotel hotel);

  /// Saklı otel seçimi. Yoksa null.
  Future<Hotel?> getSelectedHotel();

  /// Logout'ta çağrılır - seçili otel bir sonraki kullanıcıya geçmesin.
  Future<void> clearSelectedHotel();
}