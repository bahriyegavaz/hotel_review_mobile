import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// Logout: oturum verisini VE otel seçimini siler.
  /// Otel seçimi kullanıcıya özel - farklı kullanıcının otelleri farklı,
  /// bir sonraki girişte önceki kullanıcının oteli görünmemeli.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _hotelKey);
  }
}