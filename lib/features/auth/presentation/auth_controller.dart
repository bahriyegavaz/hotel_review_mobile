import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import 'auth_providers.dart';
import 'session_controller.dart';

/// Login FORMUNUN durumu. Dikkat: bu, oturum durumu değil.
/// Oturum SessionController'da tutulur. Bu controller sadece
/// "login isteği şu an ne halde" sorusunu cevaplar.
sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginInProgress extends LoginState {
  const LoginInProgress();
}

class LoginFailed extends LoginState {
  const LoginFailed(this.message);
  final String message;
}

class AuthController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginIdle();

  Future<void> login({required String email, required String password}) async {
    state = const LoginInProgress();
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );

      // Oturumu güncelle - router bunu görüp dashboard'a yönlendirecek.
      ref.read(sessionControllerProvider.notifier).setAuthenticated(user);
      state = const LoginIdle();
    } on AuthFailure catch (e) {
      state = LoginFailed(e.message);
    } catch (_) {
      state = const LoginFailed('Beklenmeyen bir hata oluştu.');
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, LoginState>(AuthController.new);