import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/action_items/presentation/action_items_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reviews/presentation/add_review_screen.dart';
import 'app_routes.dart';

/// go_router `refreshListenable` bir Listenable bekler, oturum ise Riverpod'da.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(
      sessionControllerProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,

    /// Tüm yetkilendirme mantığı burada. Ekranlar bunu düşünmez.
    ///
    /// Misafir kısıtlaması da burada uygulanıyor - yorum ekleme dışında
    /// bir yere gitmeye çalışırsa geri atılır. Ekranlarda tek tek
    /// "bu kullanıcı misafir mi" kontrolü yapmıyoruz.
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      return switch (session) {
        // Token okunuyor - splash'te bekle.
        SessionUnknown() =>
          location == AppRoutes.splash ? null : AppRoutes.splash,

        // Giriş yapılmamış - login dışında hiçbir yere gidemez.
        SessionUnauthenticated() =>
          location == AppRoutes.login ? null : AppRoutes.login,

        // Misafir - SADECE yorum ekleme ekranı.
        // Dashboard, görevler, KPI'lar ona kapalı.
        SessionGuest() =>
          location == AppRoutes.addReview ? null : AppRoutes.addReview,

        // Personel - login/splash'te takılı kalmasın.
        SessionAuthenticated() =>
          (location == AppRoutes.login || location == AppRoutes.splash)
              ? AppRoutes.dashboard
              : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.addReview,
        builder: (context, state) => const AddReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.actionItems,
        builder: (context, state) => const ActionItemsScreen(),
      ),
    ],
  );
});