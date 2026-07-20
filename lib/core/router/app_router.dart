import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/action_items/presentation/action_items_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/hotels/presentation/hotel_providers.dart';
import '../../features/hotels/presentation/hotel_selection_screen.dart';
import '../../features/reviews/presentation/add_review_screen.dart';
import '../../features/reviews/presentation/reviews_list_screen.dart';
import 'app_routes.dart';

/// Hem oturumu hem otel seçimini dinler; biri değişince router yeniden değerlendirir.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
    );
    ref.listen<HotelSelectionState>(
      selectedHotelProvider,
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

    /// İki sıralı kapı:
    ///   1. Giriş yapıldı mı?
    ///   2. Otel seçildi mi?
    /// İkisi de cihazda saklı; açılışta okunurken splash gösterilir.
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final hotel = ref.read(selectedHotelProvider);
      final location = state.matchedLocation;

      // Oturum okunuyor - bekle.
      if (session is SessionUnknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Giriş yok - login dışına çıkamaz.
      if (session is SessionUnauthenticated) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      // Buradan sonrası: giriş yapılmış.
      // Otel seçimi okunuyor - bekle.
      if (hotel is HotelUnknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Otel seçilmemiş - seçim ekranına.
      if (hotel is HotelNotSelected) {
        return location == AppRoutes.hotelSelection
            ? null
            : AppRoutes.hotelSelection;
      }

      // Giriş + otel tamam: login/splash/otel seçiminde takılı kalmasın.
      if (location == AppRoutes.login ||
          location == AppRoutes.splash ||
          location == AppRoutes.hotelSelection) {
        return AppRoutes.dashboard;
      }

      return null;
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
        path: AppRoutes.hotelSelection,
        builder: (context, state) => const HotelSelectionScreen(),
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
      GoRoute(
        path: AppRoutes.reviews,
        builder: (context, state) => const ReviewsListScreen(),
      ),
    ],
  );
});