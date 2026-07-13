import '../domain/user.dart';

/// Backend'e gönderilen login isteği.
/// POST /api/auth/login
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Backend'den dönen login yanıtı.
///
/// !!! BACKEND GELİNCE KONTROL EDİLECEK ALANLAR !!!
/// Rapor bölüm 12'ye göre response zarfı: { success, message, data, errors }
/// Bu DTO "data" içindeki objeyi temsil eder.
/// Token alan adı 'token' varsayıldı - backend 'accessToken' dönerse burası düzeltilecek.
class LoginResponseDto {
  const LoginResponseDto({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.departmentId,
  });

  final String token;
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? departmentId;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token'] as String,
      // id int de Guid de olabilir - toString() ile ikisini de karşılıyoruz.
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      departmentId: json['departmentId']?.toString(),
    );
  }

  /// DTO -> Domain modeli. Bu dönüşüm sayesinde uygulamanın geri kalanı
  /// backend'in alan isimlerinden habersiz kalır.
  User toDomain() {
    return User(
      id: userId,
      fullName: fullName,
      email: email,
      role: UserRole.fromString(role),
      departmentId: departmentId,
    );
  }
}

/// Rapor bölüm 12: standart API response modeli.
/// { "success": true, "message": "...", "data": {...}, "errors": [...] }
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  final bool success;
  final String? message;
  final T? data;
  final List<String>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: rawData is Map<String, dynamic> ? fromJsonT(rawData) : null,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}