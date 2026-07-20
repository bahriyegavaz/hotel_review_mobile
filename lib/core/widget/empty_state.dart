import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Liste/veri boş olduğunda gösterilen ortak boş durum.
///
/// İkon + başlık + açıklama, isteğe bağlı bir eylem butonu.
/// Her ekranda aynı görünsün diye tek yerde tanımlı.
///
/// Kullanım:
///   EmptyState(
///     icon: LucideIcons.inbox,
///     title: 'Görev yok',
///     message: 'Departmanınıza atanmış bir görev bulunmuyor.',
///     actionLabel: 'Yorum ekle',    // opsiyonel
///     onAction: () => ...,          // opsiyonel
///   )
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon, yumuşak renkli bir dairenin içinde - sert durmasın.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}