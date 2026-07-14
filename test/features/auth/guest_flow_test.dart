import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/auth/presentation/auth_providers.dart';
import 'package:hotel_review_mobile/features/auth/presentation/login_screen.dart';
import 'package:hotel_review_mobile/features/auth/presentation/session_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_auth_repository.dart';

List<Override> _overrides(StubAuthRepository stub) => [
      authRepositoryProvider.overrideWithValue(stub),
    ];

void main() {
  group('SessionController misafir durumu', () {
    test('continueAsGuest oturumu SessionGuest yapar', () {
      final container = ProviderContainer(
        overrides: _overrides(StubAuthRepository()),
      );
      addTearDown(container.dispose);

      container.read(sessionControllerProvider.notifier).continueAsGuest();

      expect(container.read(sessionControllerProvider), isA<SessionGuest>());
      expect(container.read(isGuestProvider), isTrue);
      // Misafirin kullanıcı kaydı yok.
      expect(container.read(currentUserProvider), isNull);
    });

    test('exitGuest oturumu kapatır', () {
      final container = ProviderContainer(
        overrides: _overrides(StubAuthRepository()),
      );
      addTearDown(container.dispose);

      final notifier = container.read(sessionControllerProvider.notifier);
      notifier.continueAsGuest();
      notifier.exitGuest();

      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
      expect(container.read(isGuestProvider), isFalse);
    });

    testWidgets('misafir durumu kalıcı değil - yeniden başlatınca kaybolur',
        (tester) async {
      // Yeni bir container, saklı kullanıcı yok.
      final container = ProviderContainer(
        overrides: _overrides(StubAuthRepository()),
      );
      addTearDown(container.dispose);

      container.read(sessionControllerProvider);
      await tester.pump();

      // Misafir durumu depolamaya yazılmadığı için Unauthenticated başlar.
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
    });
  });

  group('LoginScreen misafir butonu', () {
    testWidgets('misafir butonu görünür', (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: _overrides(StubAuthRepository()),
      );

      expect(find.text('Misafir olarak yorum bırak'), findsOneWidget);
    });

    testWidgets('misafir butonuna basınca form doğrulaması çalışmaz',
        (tester) async {
      final stub = StubAuthRepository();
      await tester.pumpApp(
        const LoginScreen(),
        overrides: _overrides(stub),
      );

      // Boş formda misafir butonuna bas.
      await tester.tap(find.text('Misafir olarak yorum bırak'));
      await tester.pump();

      // E-posta/şifre hatası çıkmamalı - misafir bunları doldurmuyor.
      expect(find.text('E-posta zorunludur.'), findsNothing);
      expect(find.text('Şifre zorunludur.'), findsNothing);
      // Login denemesi de yapılmamalı.
      expect(stub.loginCallCount, 0);
    });
  });
}