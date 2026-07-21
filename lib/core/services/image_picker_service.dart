import 'dart:io';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Fotoğraf doğrulaması başarısız olduğunda fırlatılır.
/// Ekran bunu yakalayıp [message]'ı kullanıcıya gösterir.
class PhotoValidationException implements Exception {
  const PhotoValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// image_picker paketini saran ince katman.
///
/// Neden doğrudan ImagePicker kullanmıyoruz?
/// - Ekran kodu XFile gibi paket tiplerini bilmesin, sade String yol alsın.
/// - Test yazarken bu servisi sahte bir versiyonla değiştirebilelim
///   (widget testinde gerçek kamera açılamaz).
class ImagePickerService {
  ImagePickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Backend gereksinimi (madde 6.1): fotoğraf 5 MB'ı geçmemeli.
  static const int maxSizeBytes = 5 * 1024 * 1024;

  /// İzin verilen dosya uzantıları (madde 6.1).
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png'};

  /// Kullanıcı iptal ederse null döner - bu bir hata değil, normal akış.
  ///
  /// Seçilen fotoğraf backend'e gönderilmeden ÖNCE burada doğrulanır:
  /// - uzantı .jpg/.jpeg/.png mi?
  /// - boyut 5 MB altında mı?
  /// Geçersizse [PhotoValidationException] fırlatır; ekran mesajı gösterir.
  Future<String?> pickPhoto(PhotoSource source) async {
    final image = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Yükleme boyutunu baştan kısmak için sıkıştırıyoruz - ama yine de
      // aşağıda kesin doğrulama yapıyoruz (sıkıştırma her zaman yeterli değil).
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (image == null) return null; // kullanıcı iptal etti

    final path = image.path;

    // 1. Uzantı kontrolü.
    final extension = _extensionOf(path);
    if (!allowedExtensions.contains(extension)) {
      throw const PhotoValidationException(
        'Sadece JPG, JPEG veya PNG dosyaları yükleyebilirsiniz.',
      );
    }

    // 2. Boyut kontrolü.
    final length = await File(path).length();
    if (length > maxSizeBytes) {
      throw const PhotoValidationException(
        'Fotoğraf boyutu 5 MB\'ı geçemez. Lütfen daha küçük bir fotoğraf seçin.',
      );
    }

    return path;
  }

  /// Yoldan küçük harfli uzantı çıkarır: "/a/b/Foto.JPG" -> ".jpg".
  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '';
    return path.substring(dot).toLowerCase();
  }
}