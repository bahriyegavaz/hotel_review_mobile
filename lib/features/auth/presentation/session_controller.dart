import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_providers.dart';

/// Uygulamanın oturum durumu.
/// Router bu dört durumu görerek hangi ekranı göstereceğine karar verir.
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

/// Giriş yapmadan devam eden misafir.
///
/// Sadece yorum bırakabilir. Dashboard, görevler, KPI'lar ona kapalı.
///
/// Bu durum KALICI DEĞİL - cihazda saklanmaz. Uygulama kapanıp açılınca
/// misafir tekrar login ekranını görür. Kasıtlı: misafirin bir oturumu yok,
/// bir kerelik yorum bırakma eylemi var.
class SessionGuest extends SessionState {
  const SessionGuest();
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

  /// Login ekranındaki "Misafir olarak yorum bırak" butonu.
  void continueAsGuest() => state = const SessionGuest();

  /// Misafir çıkış yapar - login ekranına döner.
  /// Depolamaya dokunmuyoruz çünkü misafir hiçbir şey saklamadı.
  void exitGuest() => state = const SessionUnauthenticated();

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SessionUnauthenticated();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Kısayol: giriş yapmış kullanıcıyı almak isteyen ekranlar için.
/// Misafir için null döner - misafirin kullanıcı kaydı yok.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SessionAuthenticated ? session.user : null;
});

/// Ekranların "misafir modunda mıyım" sorusunu sorması için.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(sessionControllerProvider) is SessionGuest;
});