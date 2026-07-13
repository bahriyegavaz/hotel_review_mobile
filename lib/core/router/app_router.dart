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
      (_, _) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,

    /// Tüm auth yönlendirme mantığı burada. Ekranlar bunu düşünmez.
    /// Giriş yapılmadan hiçbir korumalı sayfaya erişilemez.
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      return switch (session) {
        SessionUnknown() =>
          location == AppRoutes.splash ? null : AppRoutes.splash,
        SessionUnauthenticated() =>
          location == AppRoutes.login ? null : AppRoutes.login,
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