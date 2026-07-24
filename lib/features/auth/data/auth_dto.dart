import 'package:jwt_decoder/jwt_decoder.dart';

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
/// Backend `data` içinde SADECE token dönüyor:
///   { "success": true, "data": { "token": "eyJ..." } }
///
/// Kullanıcı bilgisi ayrı bir nesne olarak gelmiyor - JWT claim'lerine
/// gömülü. Bu yüzden alanları önce JSON'dan okuyoruz (ileride backend
/// eklerse çalışsın), yoksa token'ı çözüp claim'lerden alıyoruz.
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

  /// .NET'in rol claim'i uzun bir URI olarak gelir.
  static const _roleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  /// .NET bazı claim'leri de URI formatında gönderebilir - iki isim de denenir.
  static const _nameClaim =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
  static const _emailClaim =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';
  static const _idClaim =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ??
        json['accessToken'] as String? ??
        '';

    // Token'ı çöz - kullanıcı bilgisi claim'lerde.
    Map<String, dynamic> claims = const {};
    if (token.isNotEmpty) {
      try {
        claims = JwtDecoder.decode(token);
      } catch (_) {
        // Çözülemeyen token - claim'siz devam, alanlar JSON'dan gelirse gelir.
        claims = const {};
      }
    }

    /// Önce JSON'a, sonra claim'lere bakan yardımcı.
    String pick(String jsonKey, List<String> claimKeys) {
      final fromJson = json[jsonKey];
      if (fromJson != null && fromJson.toString().isNotEmpty) {
        return fromJson.toString();
      }
      for (final key in claimKeys) {
        final value = claims[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
      return '';
    }

    final departmentId = pick('departmentId', const ['departmentId']);

    return LoginResponseDto(
      token: token,
      userId: pick('userId', const ['sub', _idClaim, 'nameid', 'id']),
      fullName: pick('fullName', const ['name', _nameClaim, 'unique_name']),
      email: pick('email', const ['email', _emailClaim]),
      role: pick('role', const [_roleClaim, 'role']),
      departmentId: departmentId.isEmpty ? null : departmentId,
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
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}