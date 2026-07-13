import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/auth/domain/auth_repository.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/features/auth/presentation/login_screen.dart';
import 'package:hotel_review_mobile/features/auth/presentation/session_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

void main() {
  group('LoginScreen form validasyonu', () {
    testWidgets('boş formda gönderilince hata mesajları gösterir',
        (tester) async {
      final stub = StubAuthRepository();
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();

      expect(find.text('E-posta zorunludur.'), findsOneWidget);
      expect(find.text('Şifre zorunludur.'), findsOneWidget);
      // Validasyon geçmediği için repository'ye hiç gidilmemeli.
      expect(stub.loginCallCount, 0);
    });

    testWidgets('geçersiz e-posta formatını reddeder', (tester) async {
      final stub = StubAuthRepository();
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.enterText(find.byType(TextFormField).first, 'gecersiz');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();

      expect(find.text('Geçerli bir e-posta giriniz.'), findsOneWidget);
      expect(stub.loginCallCount, 0);
    });

    testWidgets('6 karakterden kısa şifreyi reddeder', (tester) async {
      final stub = StubAuthRepository();
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();

      expect(find.text('Şifre en az 6 karakter olmalıdır.'), findsOneWidget);
      expect(stub.loginCallCount, 0);
    });
  });

  group('LoginScreen giriş akışı', () {
    testWidgets('geçerli bilgilerle repository çağrılır ve oturum açılır',
        (tester) async {
      final stub = StubAuthRepository(loginResult: testAdmin);
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.enterText(
          find.byType(TextFormField).first, 'admin@hotel.com');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(stub.loginCallCount, 1);
    });

    testWidgets('hatalı şifrede hata mesajı SnackBar ile gösterilir',
        (tester) async {
      final stub = StubAuthRepository(failure: const InvalidCredentialsFailure());
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.enterText(
          find.byType(TextFormField).first, 'admin@hotel.com');
      await tester.enterText(find.byType(TextFormField).last, 'yanlissifre');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    });

    testWidgets('ağ hatasında ilgili mesaj gösterilir', (tester) async {
      final stub = StubAuthRepository(failure: const NetworkFailure());
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.enterText(
          find.byType(TextFormField).first, 'admin@hotel.com');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sunucuya ulaşılamadı'), findsOneWidget);
    });
  });

  group('SessionController oturum geri yükleme', () {
    testWidgets('saklı kullanıcı varsa oturum açık başlar', (tester) async {
      final stub = StubAuthRepository(currentUser: testAdmin);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );
      addTearDown(container.dispose);

      // build() içindeki _restore() asenkron - bir tur beklemek gerekiyor.
      expect(container.read(sessionControllerProvider), isA<SessionUnknown>());
      await tester.pump();
      expect(
        container.read(sessionControllerProvider),
        isA<SessionAuthenticated>(),
      );
    });

    testWidgets('saklı kullanıcı yoksa oturum kapalı başlar', (tester) async {
      final stub = StubAuthRepository();

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(stub)],
      );
      addTearDown(container.dispose);

      container.read(sessionControllerProvider);
      await tester.pump();
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
    });
  });
}