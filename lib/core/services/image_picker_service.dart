import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// image_picker paketini saran ince katman.
///
/// Neden doğrudan ImagePicker kullanmıyoruz?
/// - Ekran kodu XFile gibi paket tiplerini bilmesin, sade String yol alsın.
/// - Test yazarken bu servisi sahte bir versiyonla değiştirebilelim
///   (widget testinde gerçek kamera açılamaz).
class ImagePickerService {
  ImagePickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Kullanıcı iptal ederse null döner - bu bir hata değil, normal akış.
  Future<String?> pickPhoto(PhotoSource source) async {
    final image = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Yükleme boyutunu baştan kısmak için: 5 MB sınırına takılmayalım.
      maxWidth: 1600,
      imageQuality: 85,
    );
    return image?.path;
  }
}