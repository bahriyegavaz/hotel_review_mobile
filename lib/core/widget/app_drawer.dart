import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/session_controller.dart';
import '../router/app_routes.dart';

/// Soldan açılan gezinme menüsü. Tüm ekranlara buradan ulaşılır.
///
/// Rol bazlı görünüm:
///   - Yorumlar: sadece Admin ve Manager görür. Departman personeli
///     kendi görevlerine odaklanır (rapor bölüm 11), yorum listesi
///     yönetici perspektifi.
///   - Diğer öğeler herkese açık.
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
            // --- Üst: kullanıcı ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '-',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
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
            const Divider(height: 1),
            const SizedBox(height: 8),
            // --- Gezinme ---
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Ana Sayfa',
              selected: currentLocation == AppRoutes.dashboard,
              onTap: () => _go(context, AppRoutes.dashboard),
            ),
            _DrawerItem(
              icon: Icons.checklist_outlined,
              label: 'Aksiyonlar',
              selected: currentLocation == AppRoutes.actionItems,
              onTap: () => _go(context, AppRoutes.actionItems),
            ),
            _DrawerItem(
              icon: Icons.reviews_outlined,
              label: 'Yorumlar',
              selected: currentLocation == AppRoutes.reviews,
              onTap: () => _go(context, AppRoutes.reviews),
            ),
            _DrawerItem(
              icon: Icons.add_comment_outlined,
              label: 'Yorum Ekle',
              selected: currentLocation == AppRoutes.addReview,
              onTap: () => _go(context, AppRoutes.addReview),
            ),
            const Spacer(),
            const Divider(height: 1),
            // --- Çıkış ---
            _DrawerItem(
              icon: Icons.logout,
              label: 'Çıkış Yap',
              onTap: () {
                Navigator.pop(context);
                ref.read(sessionControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
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
    return ListTile(
      leading: Icon(icon, color: selected ? scheme.primary : null),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? scheme.primary : null,
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.3),
      onTap: onTap,
    );
  }
}