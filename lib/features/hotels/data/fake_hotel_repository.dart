import '../../../core/storage/secure_storage_service.dart';
import '../domain/hotel.dart';
import '../domain/hotel_repository.dart';
import 'hotel_dto.dart';

/// Backend hazır olmadan otel seçimini geliştirmek için.
///
/// Demo: kullanıcının 3 otelde çalıştığını varsayıyor. Backend gelince
/// bu liste login response'undan / my-hotels endpoint'inden gelecek.
class FakeHotelRepository implements HotelRepository {
  FakeHotelRepository(this._storage, {this.hotels, this.shouldFail = false});

  final SecureStorageService _storage;
  final List<Hotel>? hotels;
  final bool shouldFail;

  static const _defaultHotels = [
    Hotel(id: '1', name: 'Grand Hotel', city: 'Antalya'),
    Hotel(id: '2', name: 'Seaside Resort', city: 'Bodrum'),
    Hotel(id: '3', name: 'City Center Hotel', city: 'İstanbul'),
  ];

  @override
  Future<List<Hotel>> getMyHotels() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (shouldFail) throw const HotelNetworkFailure();
    return hotels ?? _defaultHotels;
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