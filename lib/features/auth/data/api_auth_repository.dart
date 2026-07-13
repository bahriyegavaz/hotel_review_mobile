import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_dto.dart';
import 'user_mapper.dart';

/// Gerçek .NET backend'e konuşan implementasyon.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: LoginRequestDto(email: email, password: password).toJson(),
      );

      final body = response.data;
      if (body == null) throw const UnknownAuthFailure();

      final apiResponse = ApiResponse<LoginResponseDto>.fromJson(
        body,
        LoginResponseDto.fromJson,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw UnknownAuthFailure(apiResponse.message);
      }

      final dto = apiResponse.data!;
      final user = dto.toDomain();

      await _storage.saveToken(dto.token);
      await _storage.saveUser(encodeUser(user));

      return user;
    } on DioException catch (e) {
      // Altyapı hatasını domain hatasına çeviriyoruz.
      if (e.response?.statusCode == 401) {
        throw const InvalidCredentialsFailure();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkFailure();
      }
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<void> logout() => _storage.clearSession();

  @override
  Future<User?> getCurrentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    return decodeUser(await _storage.readUser());
  }
}