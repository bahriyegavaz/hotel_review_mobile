import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT token ve oturum verisinin cihazda güvenli saklanmasından sorumlu servis.
/// iOS'ta Keychain, Android'de Keystore kullanır.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Kullanıcı bilgisi JSON string olarak saklanır.
  /// Böylece uygulama yeniden açıldığında backend'e sormadan
  /// "kim giriş yapmıştı" sorusunu cevaplayabiliriz.
  ///
  /// Not: Backend'de /api/auth/me gibi bir endpoint olsaydı, token ile
  /// profili her açılışta tazeleyebilirdik. Rapordaki API listesinde
  /// böyle bir endpoint yok, bu yüzden yerelde saklıyoruz.
  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> readUser() => _storage.read(key: _userKey);

  /// Logout: tüm oturum verisini siler.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}