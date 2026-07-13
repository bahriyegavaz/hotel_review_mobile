import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthInterceptor(
    storageService,
    onUnauthorized: () async {
      // İleride: router üzerinden login ekranına yönlendirme veya
      // bir auth state'i "loggedOut" durumuna çekme burada tetiklenecek.
    },
  );
});

final dioProvider = Provider<Dio>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  return createDioClient(authInterceptor: authInterceptor);
});