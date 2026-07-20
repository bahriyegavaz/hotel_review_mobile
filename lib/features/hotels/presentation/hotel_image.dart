import 'package:flutter/material.dart';

/// Otel id'sine göre yerel görsel döndürür.
///
/// Backend hazır olunca Hotel modeline `imageUrl` eklenip bu yardımcı
/// yerine Image.network kullanılabilir. Şimdilik demo otelleri için
/// assets/images/hotels/ altındaki görseller.
///
/// Görsel bulunamazsa default.jpg, o da yoksa düz renk fallback (widget
/// tarafında errorBuilder ile).
class HotelImage {
  HotelImage._();

  /// Bilinen demo otel id'leri -> asset. Yeni otel eklenince buraya da
  /// bir satır eklemek yeterli.
  static const Map<String, String> _byId = {
    '1': 'assets/images/hotels/1.jpeg',
    '2': 'assets/images/hotels/2.jpg',
    '3': 'assets/images/hotels/3.jpg',
  };

  static const String _default = 'assets/images/hotels/default.jpg';

  static String assetFor(String? hotelId) {
    return _byId[hotelId] ?? _default;
  }

  /// Doğrudan bir ImageProvider isteyen yerler için (DecorationImage gibi).
  static ImageProvider providerFor(String? hotelId) {
    return AssetImage(assetFor(hotelId));
  }
}