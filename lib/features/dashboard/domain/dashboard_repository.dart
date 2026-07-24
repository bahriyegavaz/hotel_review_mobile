import 'dashboard_summary.dart';

sealed class DashboardFailure implements Exception {
  const DashboardFailure(this.message);
  final String message;
}

class DashboardNetworkFailure extends DashboardFailure {
  const DashboardNetworkFailure()
    : super('Özet veriler yüklenemedi. Bağlantınızı kontrol edin.');
}

class UnknownDashboardFailure extends DashboardFailure {
  const UnknownDashboardFailure([String? message])
    : super(message ?? 'Beklenmeyen bir hata oluştu.');
}

abstract class DashboardRepository {
  /// GET /api/dashboard/summary
  ///
  /// Backend JWT'deki role ve departmana göre kapsamı belirler:
  /// Admin tüm oteli, DepartmentUser kendi departmanını görür.
  Future<DashboardSummary> getSummary();
}
