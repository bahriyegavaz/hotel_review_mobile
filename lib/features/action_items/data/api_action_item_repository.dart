import 'package:dio/dio.dart';

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
  Future<void> updateStatus({
    required String id,
    required ActionStatus status,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/action-items/$id/status',
        data: {'status': status.apiValue},
      );

      // Backend bu endpoint'te güncellenmiş nesneyi dönmüyor - sadece
      // {success, message}. data alanı hep null geliyor, o yüzden onu
      // beklemek yerine sadece success'e bakıyoruz.
      final body = response.data;
      final success = body?['success'] as bool? ?? false;
      if (!success) {
        throw UnknownActionItemFailure(body?['message'] as String?);
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> reassignDepartment({
    required String id,
    required String departmentId,
    required String departmentName,
  }) async {
    try {
      // NOT: Backend bu endpoint'i henüz sunmuyor (bkz. ActionItemRepository).
      // Hazır olunca bu çağrı olduğu gibi çalışacak. Diğer PATCH
      // endpoint'leri gibi bunun da veri dönmeyeceğini varsayıyoruz.
      final response = await _dio.patch<Map<String, dynamic>>(
        '/action-items/$id/department',
        data: {'departmentId': departmentId},
      );

      final body = response.data;
      final success = body?['success'] as bool? ?? false;
      if (!success) {
        throw UnknownActionItemFailure(body?['message'] as String?);
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ActionItem> createManualActionItem({
    required String reviewId,
    required String departmentId,
    required String departmentName,
    required String title,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/action-items',
        data: {
          'reviewId': reviewId,
          'departmentId': departmentId,
          'title': title,
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        },
      );

      // Backend sadece oluşturulan kaydın id'sini dönüyor (BaseResponse<Guid>) -
      // departman adı gibi diğer alanları echo etmiyor, zaten bildiğimiz
      // parametrelerden yerelde oluşturuyoruz.
      final body = response.data;
      final success = body?['success'] as bool? ?? false;
      final newId = body?['data'] as String?;
      if (!success || newId == null || newId.isEmpty) {
        throw UnknownActionItemFailure(body?['message'] as String?);
      }

      return ActionItem(
        id: newId,
        title: title,
        status: ActionStatus.open,
        departmentId: departmentId,
        departmentName: departmentName,
        reviewId: reviewId,
        dueDate: dueDate,
      );
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
