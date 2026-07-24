import 'package:flutter/material.dart';


class HotelImage {
  HotelImage._();

  /// Havuzdaki görseller. Yeni görsel eklemek için listeye bir satır
  /// eklemek yeterli (ve pubspec'te assets klasörü kayıtlı olmalı).
  static const List<String> _pool = [
     'assets/images/hotels/adora.jpeg',
    'assets/images/hotels/megasaray.jpeg',
    'assets/images/hotels/crystal.jpeg',
    'assets/images/hotels/rixos.jpeg',
    'assets/images/hotels/titanic.jpeg'
  ];

   static String byIndex(int index) {
    if (_pool.isEmpty) return '';
    if (index < 0) return _pool.first;
    return _pool[index % _pool.length];
  }


  static String assetFor(String? hotelId) {
    if (_pool.isEmpty) return '';
    if (hotelId == null || hotelId.isEmpty) return _pool.first;

    // id'nin karakter kodlarını toplayıp havuz boyutuna göre indeks üret.
    // Basit ama tutarlı: aynı id -> hep aynı görsel.
    var sum = 0;
    for (final unit in hotelId.codeUnits) {
      sum += unit;
    }
    return _pool[sum % _pool.length];
  }

  /// DecorationImage gibi ImageProvider isteyen yerler için.
  static ImageProvider providerFor(String? hotelId) {
    return AssetImage(assetFor(hotelId));
  }
}