import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widget/app_drawer.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../../auth/presentation/session_controller.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/presentation/review_providers.dart';
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
    final selectedDepartmentId = ref.watch(departmentFilterProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canViewAllDepartments = currentUser?.canViewAllDepartments ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Aksiyonlar')),
      body: Column(
        children: [
          // Admin/Manager tüm departmanları görür - üstte departman seçici
          // gösteriyoruz (Tümü / departman adı). Departman personeli zaten
          // sadece kendi departmanını görüyor, onlara "Tümü" yerine
          // Atanan/Açık chip'leri anlamlı.
          if (canViewAllDepartments)
            _DepartmentChips(
              departments: ref.watch(availableDepartmentsProvider),
              selected: selectedDepartmentId,
              onChanged: (value) =>
                  ref.read(departmentFilterProvider.notifier).select(value),
            )
          else
            _FilterChips(
              values: ActionFilter.departmentUserValues,
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
                    : 'Aksiyonlar yüklenemedi.',
                onRetry: () =>
                    ref.read(actionItemsControllerProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(actionItemsControllerProvider.notifier)
                          .refresh(),
                      // "Tümü" seçiliyken (tek departmana süzülmemişken)
                      // admin/manager için başlıklı bölümler halinde
                      // grupluyoruz. Belirli bir departman seçiliyken zaten
                      // tek departman kaldığı için gruplama gereksiz.
                      child: canViewAllDepartments && selectedDepartmentId == null
                          ? _GroupedActionItemsList(items: items)
                          : ListView.builder(
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

/// Görevleri departman adına göre başlıklı bölümlere ayırır.
/// Sıralama zaten filteredActionItemsProvider'da yapıldı (gecikmiş -> açık ->
/// kapalı); burada sadece o sırayı koruyarak departmana göre bölüyoruz.
class _GroupedActionItemsList extends StatelessWidget {
  const _GroupedActionItemsList({required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDepartment(items);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DepartmentHeader(name: group.key, count: group.value.length),
              const SizedBox(height: 8),
              for (final item in group.value) _ActionItemCard(item: item),
            ],
          ),
        );
      },
    );
  }

  static List<MapEntry<String, List<ActionItem>>> _groupByDepartment(
    List<ActionItem> items,
  ) {
    final map = <String, List<ActionItem>>{};
    for (final item in items) {
      final name = item.departmentName?.trim();
      final key = (name == null || name.isEmpty) ? 'Departmansız' : name;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map.entries.toList();
  }
}

class _DepartmentHeader extends StatelessWidget {
  const _DepartmentHeader({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final List<ActionFilter> values;
  final ActionFilter selected;
  final ValueChanged<ActionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final value in values) ...[
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

/// Admin/Manager için üstteki departman seçici. "Tümü" (null) + her
/// departman görevlerden türetilerek bir chip olarak gösterilir.
class _DepartmentChips extends StatelessWidget {
  const _DepartmentChips({
    required this.departments,
    required this.selected,
    required this.onChanged,
  });

  final List<(String id, String name)> departments;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tümü'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final (id, name) in departments) ...[
            ChoiceChip(
              label: Text(name),
              selected: selected == id,
              onSelected: (_) => onChanged(id),
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
          backgroundColor: errorMessage != null
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
  }

  /// AI, yorumu yanlış departmana atamışsa Admin/Manager burada düzeltir.
  /// Kişi bazlı değil departman bazlı - kişi ataması Angular panelinin işi
  /// olarak salt okunur kalıyor (bkz. ActionItem.assignedToName).
  Future<void> _reassignDepartment(
    BuildContext context,
    WidgetRef ref,
    List<(String id, String name)> departments,
  ) async {
    final selected = await showModalBottomSheet<(String, String)>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Departmanı değiştir'),
            ),
            for (final (id, name) in departments)
              ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(name),
                trailing: item.departmentId == id
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () => Navigator.pop(sheetContext, (id, name)),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    final (departmentId, departmentName) = selected;
    if (departmentId == item.departmentId) return;

    final errorMessage = await ref
        .read(actionItemsControllerProvider.notifier)
        .reassignDepartment(item.id, departmentId, departmentName);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Departman güncellendi.'),
          backgroundColor: errorMessage != null
              ? Theme.of(context).colorScheme.error
              : null,
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

    // Backend'in title'ı = yorumun ham metni (bkz. rapor). Gerçek bir
    // actionable görev cümlesi yerine review'ın AI analizinden gelen
    // öneriyi (varsa) başlık olarak kullanıyoruz - reviewId üzerinden
    // ayrıca çekiyoruz çünkü liste endpoint'i bunu içermiyor.
    //
    // ÖNEMLİ: review'ın GENEL/baskın analizini değil, bu göreve doğrudan
    // sebep olan CÜMLEYİ eşleştirip onun önerisini kullanıyoruz. Tek bir
    // review birden fazla cümle (bazısı olumlu, bazısı olumsuz) içerip
    // birden fazla göreve kaynak olabiliyor - review'ın genelini almak
    // yanlış (örn. olumlu) bir öneriyi bu negatif göreve yapıştırabilir.
    final reviewId = item.reviewId;
    final reviewDetail = reviewId == null
        ? null
        : ref.watch(reviewDetailProvider(reviewId)).value;
    final matchingClause = _matchingClause(reviewDetail, item.title);
    final fetchedSuggestion = matchingClause?.suggestion;

    // ActionItem'ın kendi bir öncelik alanı yok - backend bunu sadece
    // yorumun cümle analizinde tutuyor (bkz. ReviewClauseAnalysis). Zaten
    // öneri için çektiğimiz eşleşen cümleden önceliği de kullanıyoruz,
    // ayrı bir istek gerekmiyor.
    final priorityColor = _priorityColor(theme, matchingClause?.priority);

    final hasDirectSuggestion =
        item.suggestion != null && item.suggestion!.isNotEmpty;
    final headline = hasDirectSuggestion
        ? item.suggestion!
        : (fetchedSuggestion != null && fetchedSuggestion.isNotEmpty
              ? fetchedSuggestion
              : null);
    final isRealSuggestion = headline != null;
    final displayHeadline = headline ?? item.title;

    // Öneriyi başlık yaptıysak, ham yorum metnini altta alıntı olarak
    // göster - bağlamı kaybetmesin.
    final quotedComment =
        item.reviewComment ?? (isRealSuggestion ? item.title : null);

    // Öncelik sol kenarlıkla ambient bir sinyal olarak veriliyor - ayrı
    // bir rozet/chip eklemek karmaşayı artırırdı, bu sadece göz atarken
    // fark edilen bir renk şeridi.
    final cardContent = InkWell(
      onTap: () => _showStatusSheet(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRealSuggestion) ...[
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    displayHeadline,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: item.status),
              ],
            ),
            if (quotedComment != null) ...[
              const SizedBox(height: 8),
              Text(
                '"$quotedComment"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                // Admin/Manager AI'ın önerdiği departmanı düzeltebilir -
                // kişi bazlı değil departman bazlı (kişi ataması Angular
                // panelinin işi, mobilde salt okunur kalıyor).
                if (ref.watch(currentUserProvider)?.canViewAllDepartments ??
                    false)
                  InkWell(
                    onTap: () => _reassignDepartment(
                      context,
                      ref,
                      ref.watch(availableDepartmentsProvider),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: _MetaChip(
                      icon: Icons.apartment_outlined,
                      text: item.departmentName ?? 'Departmansız',
                    ),
                  ),
                // "Atanmamış" varsayılan bir durum - göstermek gürültü
                // yaratıyor, sadece gerçekten biri atanmışsa gösteriyoruz.
                if (item.assignedToName != null)
                  _MetaChip(
                    icon: Icons.person_outline,
                    text: item.assignedToName!,
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
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: priorityColor == null
          ? cardContent
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: priorityColor),
                  Expanded(child: cardContent),
                ],
              ),
            ),
    );
  }

  /// Görevin başlığıyla (backend title'a AI-otomatik görevlerde yorumun ham
  /// cümlesini koyuyor) eşleşen cümleyi bulur.
  ///
  /// Eşleşme bulunamazsa BİLEREK null döneriz - "en olumsuz cümleye düş"
  /// eski davranışı, title zaten bir cümle alıntısı olmadığında (örn.
  /// "Aksiyon Ekle" ile manuel oluşturulan görevlerde title zaten AI
  /// önerisinin kendisi) alakasız/rastgele bir öneriyi başlık diye
  /// gösteriyordu. Eşleşme yoksa item.title zaten doğru gösterilecek metin.
  static ReviewClauseAnalysis? _matchingClause(
    ReviewDetail? detail,
    String title,
  ) {
    if (detail == null || detail.clauseAnalyses.isEmpty) return null;

    final normalizedTitle = title.trim().toLowerCase();
    for (final clause in detail.clauseAnalyses) {
      final normalizedClause = clause.clauseText.trim().toLowerCase();
      if (normalizedClause.isNotEmpty &&
          (normalizedTitle.contains(normalizedClause) ||
              normalizedClause.contains(normalizedTitle))) {
        return clause;
      }
    }

    return null;
  }

  /// Backend'in Priority enum'u (Bilgi, Orta, Yuksek, Kritik) - sadece
  /// gerçekten aksiyon gerektiren seviyeler için renk döner, "Bilgi" ve
  /// bilinmeyen değerler için null (kenarlık gösterilmez, ekstra gürültü
  /// yaratmasın).
  static Color? _priorityColor(ThemeData theme, String? priority) {
    switch (priority?.toLowerCase()) {
      case 'kritik':
        return theme.colorScheme.error;
      case 'yuksek':
      case 'yüksek':
        return Colors.orange;
      case 'orta':
        return theme.colorScheme.tertiary;
      default:
        return null;
    }
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
        scheme.onSecondaryContainer,
      ),
      ActionStatus.inProgress => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ActionStatus.resolved => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ActionStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
      ActionStatus.unknown => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
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
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: effectiveColor),
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
      title: 'Aksiyon yok',
      message: 'Şu an bekleyen bir aksiyonunuz bulunmuyor.',
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
