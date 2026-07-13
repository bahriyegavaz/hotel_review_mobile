import 'user.dart';

/// Auth ile ilgili bilinen hata durumları.
/// UI katmanı DioException gibi altyapı sınıflarını görmez.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('E-posta veya şifre hatalı.');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure()
      : super('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([String? message])
      : super(message ?? 'Beklenmeyen bir hata oluştu.');
}

/// Auth işlemlerinin sözleşmesi.
/// Presentation katmanı SADECE bu interface'i tanır.
abstract class AuthRepository {
  /// Başarılı olursa User döner ve oturumu saklar.
  /// Başarısız olursa AuthFailure fırlatır.
  Future<User> login({required String email, required String password});

  /// Oturumu siler.
  Future<void> logout();

  /// Uygulama açılışında saklı oturumu okur.
  /// Oturum yoksa null döner.
  Future<User?> getCurrentUser();
}