import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/hotel.dart';
import '../domain/hotel_repository.dart';
import 'hotel_dto.dart';

class ApiHotelRepository implements HotelRepository {
  ApiHotelRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  /// Kullanıcının çalıştığı oteller. Auth gerektirir (JWT'den kullanıcı bulunur).
  /// Backend bunu login response'una gömerse bu endpoint gerekmeyebilir.
  static const String _myHotelsPath = '/my-hotels';

  @override
  Future<List<Hotel>> getMyHotels() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_myHotelsPath);

      final rawList = response.data?['data'];
      if (rawList is! List) return const [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => HotelDto.fromJson(json).toDomain())
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const HotelNetworkFailure();
      }
      throw UnknownHotelFailure(e.message);
    }
  }

  @override
  Future<void> saveSelectedHotel(Hotel hotel) =>
      _storage.saveHotel(encodeHotel(hotel));

  @override
  Future<Hotel?> getSelectedHotel() async =>
      decodeHotel(await _storage.readHotel());

  @override
  Future<void> clearSelectedHotel() => _storage.clearHotel();
}