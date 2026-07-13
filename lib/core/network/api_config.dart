/// Backend .NET API için temel ayarlar.
///
/// ÖNEMLİ - Simulator/Emulator farkı:
/// - iOS Simulator: "localhost" veya "127.0.0.1" çalışır çünkü simulator
///   Mac'in kendi ağını kullanır.
/// - Android Emulator: "localhost" ÇALIŞMAZ, çünkü emulator kendi izole
///   ağında çalışır. Onun yerine "10.0.2.2" kullanılmalıdır - bu adres
///   emulator içinden host makinenin localhost'una yönlenir.
/// - Gerçek cihazda test: Mac'in yerel ağ IP adresi kullanılmalı
///   (örn. 192.168.x.x), ve backend'in 0.0.0.0 üzerinde dinlemesi gerekir.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}