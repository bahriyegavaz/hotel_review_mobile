import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// JWT token, kullanıcı ve otel seçiminin cihazda saklanmasından sorumlu servis.
/// iOS'ta Keychain, Android'de Keystore kullanır.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _hotelKey = 'selected_hotel';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> readUser() => _storage.read(key: _userKey);

  /// Seçili otel. Kullanıcının o an baktığı otel.
  Future<void> saveHotel(String hotelJson) =>
      _storage.write(key: _hotelKey, value: hotelJson);

  Future<String?> readHotel() => _storage.read(key: _hotelKey);

  Future<void> clearHotel() => _storage.delete(key: _hotelKey);

  /// Saklı token'ın süresi dolmuş mu? 
  /// Backend token'ı 8 saatlik. Uygulama açılışında bu kontrol edilir;
  /// süre dolmuşsa kullanıcı sunucuya gereksiz 401'li istek atmadan doğrudan
  /// login'e yönlendirilir.
  /// Önemli davranış: token YOKSA veya ÇÖZÜLEMİYORSA (örn. fake modda gerçek
  /// bir JWT üretilmiyor) `false` döneriz - yani "dolmamış say". Böylece
  /// fake geliştirme akışı bozulmaz; gerçek JWT geldiğinde exp okunur.
  /// 
  Future<bool> isTokenExpired() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return false;

    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      // Geçerli bir JWT değil (fake token vб.) - süre kontrolü yapamayız,
      // dolmamış kabul et ki akış kırılmasın.
      return false;
    }
  }

  /// Logout: oturum verisini VE otel seçimini siler.
  /// Otel seçimi kullanıcıya özel - farklı kullanıcının otelleri farklı,
  /// bir sonraki girişte önceki kullanıcının oteli görünmemeli.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _hotelKey);
  }
}