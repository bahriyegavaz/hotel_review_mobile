import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

// ignore: unintended_html_in_doc_comment
/// Her isteğe otomatik olarak "Authorization: Bearer <token>" header'ı
/// ekler. 401 (Unauthorized) yanıtı geldiğinde saklanan oturumu temizler
/// ki uygulama login ekranına yönlendirilebilsin.
///
/// Not: 401 geldiğinde yönlendirme işini burada değil, bu interceptor'ı
/// dinleyen bir üst katmanda (router / auth state) yapmak daha doğru
/// olur; bu sınıf sadece temizlik + hatayı iletme sorumluluğunu taşır.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storageService, {this.onUnauthorized});

  final SecureStorageService _storageService;

  /// 401 alındığında dışarıya haber vermek için opsiyonel callback.
  final Future<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storageService.clearSession();
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
    }
    handler.next(err);
  }
}