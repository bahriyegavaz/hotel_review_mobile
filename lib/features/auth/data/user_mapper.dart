import 'dart:convert';

import '../domain/user.dart';

/// User modelini secure storage'da saklamak için JSON'a çevirir.
///
/// Bu dönüşüm neden domain/user.dart içinde değil?
/// Çünkü domain katmanı serileştirme bilmemeli. `User` sınıfı
/// "kullanıcı nedir" sorusunu cevaplar; "nasıl saklanır" data katmanının işi.
String encodeUser(User user) {
  return jsonEncode({
    'id': user.id,
    'fullName': user.fullName,
    'email': user.email,
    'role': user.role.name,
    'departmentId': user.departmentId,
  });
}

/// Saklanan JSON'u User'a çevirir. Bozuk/eksik veri gelirse null döner
/// ki uygulama çökmesin, kullanıcı sadece tekrar login olsun.
User? decodeUser(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return User(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      departmentId: map['departmentId'] as String?,
    );
  } catch (_) {
    return null;
  }
}