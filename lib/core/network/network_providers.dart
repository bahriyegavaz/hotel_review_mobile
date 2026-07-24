import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';
import 'hotel_header_interceptor.dart';

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

final hotelHeaderInterceptorProvider = Provider<HotelHeaderInterceptor>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return HotelHeaderInterceptor(storageService);
});

final dioProvider = Provider<Dio>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  final hotelHeaderInterceptor = ref.watch(hotelHeaderInterceptorProvider);
  return createDioClient(
    authInterceptor: authInterceptor,
    hotelHeaderInterceptor: hotelHeaderInterceptor,
  );
});