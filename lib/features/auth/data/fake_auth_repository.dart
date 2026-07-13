import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'user_mapper.dart';

/// Backend hazır olmadan geliştirme ve test için sahte implementasyon.
///
/// Demo kullanıcıları (şifre hepsinde: 123456):
///   admin@hotel.com     -> Admin
///   manager@hotel.com   -> Manager
///   temizlik@hotel.com  -> DepartmentUser (Housekeeping)
///
/// Hata senaryosu testi:
///   timeout@hotel.com   -> NetworkFailure fırlatır
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._storage);

  final SecureStorageService _storage;

  static const _validPassword = '123456';

  static final Map<String, User> _users = {
    'admin@hotel.com': const User(
      id: '1',
      fullName: 'Demo Admin',
      email: 'admin@hotel.com',
      role: UserRole.admin,
    ),
    'manager@hotel.com': const User(
      id: '2',
      fullName: 'Demo Müdür',
      email: 'manager@hotel.com',
      role: UserRole.manager,
    ),
    'temizlik@hotel.com': const User(
      id: '3',
      fullName: 'Housekeeping Personeli',
      email: 'temizlik@hotel.com',
      role: UserRole.departmentUser,
      departmentId: '10',
    ),
  };

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();

    // Ağ hatası ekranını backend'i kapatmadan test edebilmek için.
    if (normalized == 'timeout@hotel.com') {
      await Future<void>.delayed(const Duration(seconds: 2));
      throw const NetworkFailure();
    }

    // Gerçek ağ gecikmesini taklit et - loading spinner'ı görebilelim.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final user = _users[normalized];
    if (user == null || password != _validPassword) {
      throw const InvalidCredentialsFailure();
    }

    await _storage.saveToken('fake-jwt-token-for-${user.id}');
    await _storage.saveUser(encodeUser(user));

    return user;
  }

  @override
  Future<void> logout() => _storage.clearSession();

  @override
  Future<User?> getCurrentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    return decodeUser(await _storage.readUser());
  }
}