import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widget/app_drawer.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../domain/action_item.dart';
import '../domain/action_item_repository.dart';
import 'action_item_providers.dart';
import 'action_items_controller.dart';

class ActionItemsScreen extends ConsumerWidget {
  const ActionItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredActionItemsProvider);
    final filter = ref.watch(actionFilterProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Görevlerim')),
      body: Column(
        children: [
          _FilterChips(
            selected: filter,
            onChanged: (value) =>
                ref.read(actionFilterProvider.notifier).select(value),
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              loading: () => const ListSkeleton(),
              error: (error, _) => _ErrorView(
                message: error is ActionItemFailure
                    ? error.message
                    : 'Görevler yüklenemedi.',
                onRetry: () =>
                    ref.read(actionItemsControllerProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(actionItemsControllerProvider.notifier)
                          .refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _ActionItemCard(item: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final ActionFilter selected;
  final ValueChanged<ActionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final value in ActionFilter.values) ...[
            ChoiceChip(
              label: Text(value.label),
              selected: selected == value,
              onSelected: (_) => onChanged(value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ActionItemCard extends ConsumerWidget {
  const _ActionItemCard({required this.item});

  final ActionItem item;

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    ActionStatus newStatus,
  ) async {
    final errorMessage = await ref
        .read(actionItemsControllerProvider.notifier)
        .updateStatus(item.id, newStatus);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Durum güncellendi.'),
          backgroundColor:
              errorMessage != null ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Durumu güncelle'),
            ),
            for (final status in ActionStatus.selectable)
              ListTile(
                leading: Icon(_statusIcon(status)),
                title: Text(status.label),
                trailing: item.status == status
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (item.status != status) {
                    _changeStatus(context, ref, status);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatusSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: item.status),
                ],
              ),
              if (item.reviewComment != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.reviewComment!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (item.suggestion != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.suggestion!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _MetaChip(
                    icon: Icons.person_outline,
                    text: item.assignedToName ?? 'Atanmamış',
                  ),
                  if (item.dueDate != null)
                    _MetaChip(
                      icon: Icons.event_outlined,
                      text: _formatDate(item.dueDate!),
                      color: item.isOverdue ? theme.colorScheme.error : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  static IconData _statusIcon(ActionStatus status) => switch (status) {
        ActionStatus.open => Icons.radio_button_unchecked,
        ActionStatus.inProgress => Icons.timelapse,
        ActionStatus.resolved => Icons.check_circle_outline,
        ActionStatus.rejected => Icons.cancel_outlined,
        ActionStatus.unknown => Icons.help_outline,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ActionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (background, foreground) = switch (status) {
      ActionStatus.open => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      ActionStatus.inProgress => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      ActionStatus.resolved => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      ActionStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
      ActionStatus.unknown => (
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).hintColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: effectiveColor),
        ),
      ],
    );
  }
}

/// Filtreye göre görev olmadığında gösterilir.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.check_circle_outline,
      title: 'Görev yok',
      message: 'Şu an bekleyen bir göreviniz bulunmuyor.',
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}