import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/api_hotel_repository.dart';
import '../data/fake_hotel_repository.dart';
import '../domain/hotel.dart';
import '../domain/hotel_repository.dart';

/// Backend hazır olduğunda defaultValue'yu false yap.
const bool useFakeHotels = bool.fromEnvironment(
  'USE_FAKE_HOTELS',
  defaultValue: true,
);

final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  if (useFakeHotels) {
    return FakeHotelRepository(storage);
  }
  return ApiHotelRepository(ref.watch(dioProvider), storage);
});

/// Kullanıcının çalıştığı oteller. Otel seçim ekranı bunu izler.
final myHotelsProvider = FutureProvider<List<Hotel>>((ref) {
  return ref.watch(hotelRepositoryProvider).getMyHotels();
});

// ---------------------------------------------------------------
// Seçili otel durumu
// ---------------------------------------------------------------

sealed class HotelSelectionState {
  const HotelSelectionState();
}

/// Saklı seçim okunuyor. Splash gösterilir.
class HotelUnknown extends HotelSelectionState {
  const HotelUnknown();
}

/// Henüz otel seçilmemiş. Otel seçim ekranı gösterilir.
class HotelNotSelected extends HotelSelectionState {
  const HotelNotSelected();
}

class HotelSelected extends HotelSelectionState {
  const HotelSelected(this.hotel);
  final Hotel hotel;
}

/// Seçili otelin tek doğruluk kaynağı.
///
/// SessionController ile aynı desen: saklı veriyi okur, router bunu dinler.
/// Otel seçimi oturuma bağlı - logout olunca temizlenir (clearSelectedHotel).
class SelectedHotelController extends Notifier<HotelSelectionState> {
  @override
  HotelSelectionState build() {
    // Oturum kapanınca otel seçimini de sıfırla.
    // Farklı kullanıcının otelleri farklı; önceki seçim taşınmamalı.
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next is SessionUnauthenticated) {
        _reset();
      }
    });

    _restore();
    return const HotelUnknown();
  }

  Future<void> _restore() async {
    final hotel = await ref.read(hotelRepositoryProvider).getSelectedHotel();
    state = hotel != null ? HotelSelected(hotel) : const HotelNotSelected();
  }

  Future<void> _reset() async {
    await ref.read(hotelRepositoryProvider).clearSelectedHotel();
    state = const HotelNotSelected();
  }

  Future<void> select(Hotel hotel) async {
    await ref.read(hotelRepositoryProvider).saveSelectedHotel(hotel);
    state = HotelSelected(hotel);
  }

  /// "Otel değiştir" - seçimi sıfırlar. Router otel seçim ekranına atar.
  Future<void> clearSelection() async {
    await ref.read(hotelRepositoryProvider).clearSelectedHotel();
    state = const HotelNotSelected();
  }
}

final selectedHotelProvider =
    NotifierProvider<SelectedHotelController, HotelSelectionState>(
  SelectedHotelController.new,
);

/// Kısayol: seçili oteli almak isteyen ekranlar için.
final currentHotelProvider = Provider<Hotel?>((ref) {
  final state = ref.watch(selectedHotelProvider);
  return state is HotelSelected ? state.hotel : null;
});