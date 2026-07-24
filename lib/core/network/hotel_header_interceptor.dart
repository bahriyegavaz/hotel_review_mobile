import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

// ignore: unintended_html_in_doc_comment
/// Her isteğe, kullanıcının o an seçili olduğu otelin id'sini
/// "X-Hotel-Id" header'ı olarak ekler.
///
/// Backend Dashboard/Reviews/ActionItems endpoint'leri bunu (veya eşdeğer
/// ?hotelId= query parametresini) okuyup sonucu o otele göre filtreliyor -
/// header'sız istekte hangi otele bakıldığı belirsiz kalıyor, bu yüzden
/// otel değiştirmenin ekranlara hiç yansımadığı görülüyordu.
class HotelHeaderInterceptor extends Interceptor {
  HotelHeaderInterceptor(this._storageService);

  final SecureStorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final hotelJson = await _storageService.readHotel();
    if (hotelJson != null && hotelJson.isNotEmpty) {
      try {
        final map = jsonDecode(hotelJson) as Map<String, dynamic>;
        final id = map['id'] as String?;
        if (id != null && id.isNotEmpty) {
          options.headers['X-Hotel-Id'] = id;
        }
      } catch (_) {
        // Bozuk/eski format veri gelirse header'sız devam et - istek
        // otel filtresiz gider ama uygulama çökmez.
      }
    }
    handler.next(options);
  }
}
