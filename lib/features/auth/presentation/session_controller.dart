import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_providers.dart';

/// Uygulamanın oturum durumu.
/// Router bu üç durumu görerek hangi ekranı göstereceğine karar verir.
sealed class SessionState {
  const SessionState();
}

/// Uygulama yeni açıldı, saklı token okunuyor. Splash gösterilir.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);
  final User user;
}

/// Oturumun tek doğruluk kaynağı.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    // build() senkron olmak zorunda, restore'u başlatıp Unknown döndürüyoruz.
    _restore();
    return const SessionUnknown();
  }

  Future<void> _restore() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    state = user != null
        ? SessionAuthenticated(user)
        : const SessionUnauthenticated();
  }

  /// AuthController başarılı login sonrası çağırır.
  void setAuthenticated(User user) => state = SessionAuthenticated(user);

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SessionUnauthenticated();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Kısayol: giriş yapmış kullanıcıyı almak isteyen ekranlar için.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SessionAuthenticated ? session.user : null;
});