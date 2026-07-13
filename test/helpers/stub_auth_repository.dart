import 'package:hotel_review_mobile/features/auth/domain/auth_repository.dart';
import 'package:hotel_review_mobile/features/auth/domain/user.dart';

/// Testler için sahte AuthRepository.
///
/// Neden lib/'deki FakeAuthRepository'yi kullanmıyoruz?
/// Çünkü o SecureStorageService'e bağımlı, o da FlutterSecureStorage'a.
/// FlutterSecureStorage bir platform plugin'i - widget testinde iOS Keychain
/// diye bir şey yok, çağrı hata verir.
///
/// Bu stub hiçbir platform servisine dokunmaz, tamamen bellekte çalışır.
/// Testlerin hızlı ve deterministik olmasını sağlar.
class StubAuthRepository implements AuthRepository {
  StubAuthRepository({this.loginResult, this.failure, this.currentUser});

  /// login() başarılı olursa dönecek kullanıcı.
  final User? loginResult;

  /// login() bunu fırlatır (loginResult'tan önce kontrol edilir).
  final AuthFailure? failure;

  /// getCurrentUser() bunu döner - oturum açıkmış gibi davranmak için.
  final User? currentUser;

  int loginCallCount = 0;
  int logoutCallCount = 0;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCallCount++;
    if (failure != null) throw failure!;
    if (loginResult != null) return loginResult!;
    throw const UnknownAuthFailure('Stub yapılandırılmamış.');
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<User?> getCurrentUser() async => currentUser;
}

/// Testlerde sık kullanılan örnek kullanıcılar.
const testAdmin = User(
  id: '1',
  fullName: 'Test Admin',
  email: 'admin@hotel.com',
  role: UserRole.admin,
);

/// FakeActionItemRepository'deki görevlerin atandığı kullanıcı (id: '3').
const testDepartmentUser = User(
  id: '3',
  fullName: 'Housekeeping Personeli',
  email: 'temizlik@hotel.com',
  role: UserRole.departmentUser,
  departmentId: '10',
);