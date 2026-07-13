/// Route yolları tek yerde. Ekranlarda '/dashboard' gibi çıplak string
/// yazmak yerine AppRoutes.dashboard kullanılır - yazım hatası derlemede yakalanır.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String addReview = '/reviews/new';
  static const String actionItems = '/action-items';

  


  // İleride eklenecekler (rapor bölüm 11):
  // static const String actionItems = '/action-items';
}