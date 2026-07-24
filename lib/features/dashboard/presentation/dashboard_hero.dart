import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hotels/domain/hotel.dart';
import '../../hotels/presentation/hotel_image.dart';
import '../../hotels/presentation/hotel_providers.dart';

/// Dashboard'ın üst "hero" başlığı.
///
/// Arka planda seçili otelin fotoğrafı, üstünde koyu gradient (yazı
/// okunsun diye), otel seçici ve selamlama. Otel değişince fotoğraf
/// otomatik değişir.
///
/// Fotoğraf otelin LİSTEDEKİ SIRASINA göre seçiliyor (id'ye göre değil) -
/// böylece GUID gibi id'lerde çakışma olmaz, her otel farklı görsel alır.
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
    final hotels = ref.watch(myHotelsProvider).value ?? const <Hotel>[];

    // Seçili otelin listedeki sırası -> hangi görseli alacağı.
    final rawIndex = hotel == null
        ? -1
        : hotels.indexWhere((h) => h.id == hotel.id);
    final imageIndex = rawIndex < 0 ? 0 : rawIndex;

    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- Arka plan: otel fotoğrafı ---
          Image.asset(
            HotelImage.byIndex(imageIndex),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF1E293B)),
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
                      // Menü ikonu solda.
                      _CircleIconButton(icon: Icons.menu, onTap: onOpenMenu),
                      // Otel seçici ortada - adı uzasa da ortalı kalır.
                      Expanded(
                        child: Center(
                          child: _HotelSelectorMenu(current: hotel),
                        ),
                      ),
                      // Sağda menü ikonu genişliği kadar boşluk - simetri için.
                      const SizedBox(width: 44),
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

class _HotelSelectorMenu extends ConsumerStatefulWidget {
  const _HotelSelectorMenu({required this.current});

  final Hotel? current;

  @override
  ConsumerState<_HotelSelectorMenu> createState() => _HotelSelectorMenuState();
}

class _HotelSelectorMenuState extends ConsumerState<_HotelSelectorMenu> {
  final _pillKey = GlobalKey();

  void _openMenu() {
    final hotels = ref.read(myHotelsProvider).value ?? const <Hotel>[];
    if (hotels.isEmpty) return;

    // Pill'in ekrandaki konumu ve boyutu - menüyü tam altına koymak için.
    final box = _pillKey.currentContext!.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, _, child) {
        final scheme = Theme.of(context).colorScheme;
        final hotels = ref.read(myHotelsProvider).value ?? const <Hotel>[];
        final current = widget.current;

        return Stack(
          children: [
            // Menü, pill'in tam altında.
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 8,
              width: 260,
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  ),
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        // Arkadaki fotoğrafı bulanıklaştır - buzlu cam.
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            // Yarı saydam - blur'lu arka plan görünsün.
                            color: scheme.surface.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final hotel in hotels)
                                _HotelRow(
                                  hotel: hotel,
                                  selected: hotel.id == current?.id,
                                  onTap: () {
                                    ref
                                        .read(selectedHotelProvider.notifier)
                                        .select(hotel);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.current;

    return GestureDetector(
      onTap: _openMenu,
      child: Container(
        key: _pillKey,
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

/// Menü içindeki tek otel satırı. Buzlu cam üstünde okunur renkler.
class _HotelRow extends StatelessWidget {
  const _HotelRow({
    required this.hotel,
    required this.selected,
    required this.onTap,
  });

  final Hotel hotel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.apartment_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hotel.name,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (hotel.city != null)
                    Text(
                      hotel.city!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 18, color: scheme.primary),
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