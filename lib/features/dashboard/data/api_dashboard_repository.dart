import 'package:dio/dio.dart';

import '../../auth/data/auth_dto.dart' show ApiResponse;
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_dto.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);

  final Dio _dio;

  /// GET /api/dashboard/summary
  /// Rapor bölüm 8'de tanımlı: "KPI kartları için özet veri döner"
  /// Başında /api yok çünkü ApiConfig.baseUrl zaten .../api ile bitiyor.
  static const String _summaryPath = '/dashboard/summary';

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_summaryPath);

      final body = response.data;
      if (body == null) throw const UnknownDashboardFailure();

      final apiResponse = ApiResponse<DashboardSummaryDto>.fromJson(
        body,
        DashboardSummaryDto.fromJson,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw UnknownDashboardFailure(apiResponse.message);
      }

      return apiResponse.data!.toDomain();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const DashboardNetworkFailure();
      }
      throw UnknownDashboardFailure(e.message);
    }
  }
}