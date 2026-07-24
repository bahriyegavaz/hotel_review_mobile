/// Route yolları tek yerde. Yazım hatası derlemede yakalanır.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String hotelSelection = '/hotel-selection';
  static const String dashboard = '/dashboard';
  static const String reviews = '/reviews';
  static const String addReview = '/reviews/new';
  static const String reviewDetail = '/reviews/:id';
  static const String reviewAnalysis = '/reviews/:id/analysis';
  static const String actionItems = '/action-items';
}