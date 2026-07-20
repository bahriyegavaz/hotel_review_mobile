import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hotels/domain/hotel.dart';
import '../../hotels/presentation/hotel_image.dart';
import '../../hotels/presentation/hotel_providers.dart';

/// Dashboard'ın üst "hero" başlığı.
///
/// Arka planda seçili otelin fotoğrafı, üstünde koyu gradient (yazı
/// okunsun diye), otel seçici ve selamlama. Otel değişince fotoğraf
/// otomatik değişir - currentHotelProvider'ı dinliyor.
///
/// Otel seçimi artık pill'in altında açılan dropdown (PopupMenu) - ok
/// aşağıyı gösteriyor, menü de orada açılıyor.
class DashboardHero extends ConsumerWidget {
  const DashboardHero({
    super.key,
    required this.userName,
    required this.onOpenMenu,
  });

  final String? userName;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = ref.watch(currentHotelProvider);

    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- Arka plan: otel fotoğrafı ---
          Image.asset(
            HotelImage.assetFor(hotel?.id),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1E293B),
            ),
          ),
          // --- Koyu gradient overlay ---
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0F172A),
                  Color(0x99000000),
                  Color(0xE60F172A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // --- İçerik ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _HotelSelectorMenu(current: hotel)),
                      const SizedBox(width: 12),
                      _CircleIconButton(
                        icon: Icons.menu,
                        onTap: onOpenMenu,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${_greeting(DateTime.now().hour)} ${userName ?? ''} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bugünün özetine göz atın',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting(int hour) {
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'Merhaba';
    return 'İyi akşamlar';
  }
}

// dashboard_hero.dart içindeki _HotelSelectorMenu sınıfının TAMAMINI
// bununla değiştir. (class _HotelSelectorMenu ... } bloğu)

/// "İşletme: Grand Hotel ▾" - dokununca altında dropdown açılır.
/// Menü: daha yuvarlak köşeler + hafif mavi (primaryContainer) zemin,
/// temayla uyumlu.
class _HotelSelectorMenu extends ConsumerWidget {
  const _HotelSelectorMenu({required this.current});

  final Hotel? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hotelsAsync = ref.watch(myHotelsProvider);
    final hotels = hotelsAsync.value ?? const <Hotel>[];

    return PopupMenuButton<Hotel>(
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      // Hafif mavi zemin - temanın primaryContainer'ı.
      color: scheme.primaryContainer,
      // Daha yumuşak köşeler.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 3,
      onSelected: (hotel) {
        ref.read(selectedHotelProvider.notifier).select(hotel);
      },
      itemBuilder: (context) => [
        for (final hotel in hotels)
          PopupMenuItem<Hotel>(
            value: hotel,
            child: Row(
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  // Mavi zeminde okunur ton.
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hotel.name,
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                      if (hotel.city != null)
                        Text(
                          hotel.city!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                    ],
                  ),
                ),
                if (hotel.id == current?.id)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'İşletme',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    current?.name ?? 'Seçilmedi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}