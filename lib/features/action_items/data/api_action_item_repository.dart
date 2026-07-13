import 'package:dio/dio.dart';

import '../../auth/data/auth_dto.dart' show ApiResponse;
import '../domain/action_item.dart';
import '../domain/action_item_repository.dart';
import 'action_item_dto.dart';

class ApiActionItemRepository implements ActionItemRepository {
  ApiActionItemRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<ActionItem>> getActionItems() async {
    try {
      // Query parametresi göndermiyoruz - backend JWT'den role ve
      // department_id okuyup filtreliyor. Stajyer 2 ile doğrulanacak:
      // eğer ?departmentId=X bekliyorsa buraya eklenecek.
      final response = await _dio.get<Map<String, dynamic>>('/action-items');

      final rawList = response.data?['data'];
      if (rawList is! List) return const [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => ActionItemDto.fromJson(json).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ActionItem> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/action-items/$id/status',
        data: {'status': status.apiValue},
      );

      final body = response.data;
      if (body == null) throw const UnknownActionItemFailure();

      final apiResponse = ApiResponse<ActionItemDto>.fromJson(
        body,
        ActionItemDto.fromJson,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw UnknownActionItemFailure(apiResponse.message);
      }

      return apiResponse.data!.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ActionItemFailure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ActionItemNetworkFailure();
    }
    // 403: rolü yetmiyor. 401 ise AuthInterceptor zaten session'ı temizler.
    if (e.response?.statusCode == 403) {
      return const ActionItemForbiddenFailure();
    }
    return UnknownActionItemFailure(e.message);
  }
}