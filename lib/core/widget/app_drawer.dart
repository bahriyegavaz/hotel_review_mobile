import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/session_controller.dart';
import '../../features/hotels/presentation/hotel_providers.dart';
import '../router/app_routes.dart';
import '../theme/app_theme.dart';

/// Soldan açılan gezinme menüsü. Tüm ekranlara buradan ulaşılır.
///
/// Üstte kullanıcı + seçili otel (açılır menüyle değiştirilebilir),
/// ortada gezinme, altta çıkış.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final scheme = Theme.of(context).colorScheme;
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Üst: kullanıcı (hafif tonlu şerit üstünde) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.06)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primary,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '-',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // --- Otel seçici (açılır) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _HotelSelector(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            // --- Gezinme: Ana Sayfa -> Görevler -> Yorumlar -> Yorum Ekle ---
            _DrawerItem(
              icon: LucideIcons.house,
              label: 'Ana Sayfa',
              selected: currentLocation == AppRoutes.dashboard,
              onTap: () => _go(context, AppRoutes.dashboard),
            ),
            _DrawerItem(
              icon: LucideIcons.list_checks,
              label: 'Görevler',
              selected: currentLocation == AppRoutes.actionItems,
              onTap: () => _go(context, AppRoutes.actionItems),
            ),
            _DrawerItem(
              icon: LucideIcons.message_square,
              label: 'Yorumlar',
              selected: currentLocation == AppRoutes.reviews,
              onTap: () => _go(context, AppRoutes.reviews),
            ),
            _DrawerItem(
              icon: LucideIcons.message_square_plus,
              label: 'Yorum Ekle',
              selected: currentLocation == AppRoutes.addReview,
              onTap: () => _go(context, AppRoutes.addReview),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 4),
            // --- Çıkış ---
            _DrawerItem(
              icon: LucideIcons.log_out,
              label: 'Çıkış Yap',
              onTap: () {
                Navigator.pop(context);
                ref.read(sessionControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// go_router ile git ve drawer'ı kapat. Aynı ekrandaysak sadece kapanır.
  void _go(BuildContext context, String route) {
    final current = GoRouterState.of(context).matchedLocation;
    Navigator.pop(context);
    if (current != route) {
      context.go(route);
    }
  }
}

/// Seçili oteli gösterir; dokununca kullanıcının diğer otellerini açar.
/// Seçim ekran değiştirmeden, yerinde yapılır.
class _HotelSelector extends ConsumerWidget {
  const _HotelSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentHotel = ref.watch(currentHotelProvider);
    final hotelsAsync = ref.watch(myHotelsProvider);
    final scheme = Theme.of(context).colorScheme;

    if (currentHotel == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // ExpansionTile'ın üstteki-alttaki çizgisini gizle.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(LucideIcons.hotel, color: scheme.primary, size: 20),
          title: Text(
            currentHotel.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: currentHotel.city != null ? Text(currentHotel.city!) : null,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            hotelsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Oteller yüklenemedi.'),
              ),
              data: (hotels) {
                final others =
                    hotels.where((h) => h.id != currentHotel.id).toList();
                if (others.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Başka otel yok.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final hotel in others)
                      ListTile(
                        dense: true,
                        leading: const SizedBox(width: 24),
                        title: Text(hotel.name),
                        subtitle: hotel.city != null ? Text(hotel.city!) : null,
                        onTap: () {
                          // Oteli değiştir, drawer'ı kapat. Ekran aynı kalır,
                          // seçili otel değiştiği için veriler yenilenir.
                          ref
                              .read(selectedHotelProvider.notifier)
                              .select(hotel);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? scheme.primary : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
