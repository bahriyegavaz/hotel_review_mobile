import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';

/// Uygulama genelinde kullanılacak tek Dio instance'ını oluşturur.
/// Base URL, timeout ve auth interceptor burada tanımlanır; feature
/// katmanlarındaki repository'ler bu client'ı enjekte edilmiş olarak alır.
Dio createDioClient({required AuthInterceptor authInterceptor}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(authInterceptor);

  // Geliştirme sırasında istek/yanıtları görmek için basit bir log.
  // Prod build'de kapatmak istersen kDebugMode kontrolü eklenebilir.
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
}