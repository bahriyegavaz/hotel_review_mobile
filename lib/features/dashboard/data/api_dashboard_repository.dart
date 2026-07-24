import 'package:dio/dio.dart';

import '../../auth/data/auth_dto.dart' show ApiResponse;
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_dto.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);

  final Dio _dio;

  /// Başında /api yok çünkü ApiConfig.baseUrl zaten .../api ile bitiyor.
  static const String _summaryPath = '/dashboard/summary';
  static const String _trendsPath = '/dashboard/trends';
  static const String _categoryDistributionPath =
      '/dashboard/category-distribution';
  static const String _topKeywordsPath = '/dashboard/top-keywords';

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      // KPI kartları kritik - başarısız olursa tüm ekran hata gösterir.
      final summaryDto = await _fetchSummary();

      // Grafik verileri ikincil - biri başarısız olsa da KPI kartları
      // görünsün diye ayrı ayrı ve hataya toleranslı çekiyoruz.
      final results = await Future.wait([
        _fetchTrends(),
        _fetchCategoryDistribution(),
        _fetchTopKeywords(),
      ]);

      return DashboardSummary(
        todayReviewCount: summaryDto.todayReviewCount,
        openActionCount: summaryDto.openActionCount,
        negativeReviewCount: summaryDto.negativeReviewCount,
        totalReviewCount: summaryDto.totalReviews,
        averageRating: summaryDto.averageRating,
        ratingTrend: results[0] as List<DailyRatingPoint>,
        categoryDistribution: results[1] as List<CategoryDistributionItem>,
        recurringComplaints: results[2] as List<RecurringComplaint>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<DashboardSummaryDto> _fetchSummary() async {
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

    return apiResponse.data!;
  }

  Future<List<DailyRatingPoint>> _fetchTrends() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_trendsPath);
      final rawList = response.data?['data'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => DailyRatingPointDto.fromJson(json).toDomain())
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<List<CategoryDistributionItem>> _fetchCategoryDistribution() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _categoryDistributionPath,
      );
      final rawList = response.data?['data'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => CategoryDistributionItemDto.fromJson(json).toDomain())
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<List<RecurringComplaint>> _fetchTopKeywords() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_topKeywordsPath);
      final rawList = response.data?['data'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => RecurringComplaintDto.fromJson(json).toDomain())
          .toList();
    } on DioException {
      return const [];
    }
  }

  DashboardFailure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout) {
      return const DashboardNetworkFailure();
    }
    return UnknownDashboardFailure(e.message);
  }
}
