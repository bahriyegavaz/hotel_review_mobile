import 'dart:convert';

import '../domain/hotel.dart';

/// !!! BACKEND GELİNCE KONTROL EDİLECEK !!!
/// Alan adları tahmin - raporda hotels tablosu hiç yok.
class HotelDto {
  const HotelDto({required this.id, required this.name, this.city});

  final String id;
  final String name;
  final String? city;

  factory HotelDto.fromJson(Map<String, dynamic> json) {
    return HotelDto(
      // id int de Guid de olabilir.
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String?,
    );
  }

  Hotel toDomain() => Hotel(id: id, name: name, city: city);
}

/// Seçili oteli cihazda saklamak için JSON'a çevirir.
/// Domain katmanı serileştirme bilmemeli - bu yüzden burada.
String encodeHotel(Hotel hotel) => jsonEncode({
      'id': hotel.id,
      'name': hotel.name,
      'city': hotel.city,
    });

/// Bozuk veri gelirse null döner, uygulama çökmez - kullanıcı tekrar seçer.
Hotel? decodeHotel(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final id = map['id'] as String? ?? '';
    if (id.isEmpty) return null;
    return Hotel(
      id: id,
      name: map['name'] as String? ?? '',
      city: map['city'] as String?,
    );
  } catch (_) {
    return null;
  }
}