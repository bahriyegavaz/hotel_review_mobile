import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widget/app_drawer.dart';
import '../../action_items/domain/action_item.dart';
import '../../auth/presentation/session_controller.dart';
import '../../hotels/domain/hotel.dart';
import '../../hotels/presentation/hotel_providers.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_hero.dart';
import 'dashboard_preview_providers.dart';
import 'dashboard_providers.dart';
import 'negative_trend_chart.dart';

/// Negatif/uyarı vurgusu için yumuşak kırmızı tonları.
/// Temanın parlak error rengi yerine soft, göz yormayan pastel.
/// Tek yerden ayarlanır - üç yerde kullanılır.
class _Warn {
  _Warn._();
  static const Color color = Color.fromARGB(255, 211, 127, 135);
  static const Color surface = Color(0xFFFCEDEE);
  static const Color onSurface = Color(0xFF8A3B43);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void showHotelPicker() {
    final hotels = ref.read(myHotelsProvider).value ?? const <Hotel>[];
    final current = ref.read(currentHotelProvider);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'İşletme Seç',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final hotel in hotels)
              ListTile(
                leading: Icon(
                  Icons.apartment_outlined,
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                title: Text(hotel.name),
                subtitle: hotel.city != null ? Text(hotel.city!) : null,
                trailing: hotel.id == current?.id
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(selectedHotelProvider.notifier).select(hotel);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardControllerProvider);
    final urgentAsync = ref.watch(urgentActionItemsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addReview),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Yorum Ekle'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Builder(
              builder: (context) => DashboardHero(
                userName: user?.fullName,
                onOpenMenu: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                child: Column(
                  children: [
                    summaryAsync.when(
                      loading: () => const _LoadingCards(),
                      error: (error, _) => _SummaryError(
                        message: error is DashboardFailure
                            ? error.message
                            : 'Özet veriler yüklenemedi.',
                        onRetry: () => ref
                            .read(dashboardControllerProvider.notifier)
                            .refresh(),
                      ),
                      data: (summary) => _SummaryCards(summary: summary),
                    ),
                    const SizedBox(height: 24),
                    _UrgentTasksSection(
                      urgentAsync: urgentAsync,
                      onSeeAll: () => context.push(AppRoutes.actionItems),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasNegativeDetail = summary.negativeTrend.isNotEmpty ||
        summary.recurringComplaints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.message_square,
                iconColor: scheme.primary,
                label: 'Bugünkü yorum',
                value: '${summary.todayReviewCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.clipboard_list,
                iconColor: scheme.tertiary,
                label: 'Açık görev',
                value: '${summary.openActionCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              // Negatif kart - soft kırmızı (uyarı vurgusu, yumuşatılmış).
              child: _KpiCard(
                icon: LucideIcons.frown,
                iconColor: _Warn.color,
                label: 'Negatif yorum',
                value: '${summary.negativeReviewCount}',
                tinted: true,
                tintColor: _Warn.surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.star,
                iconColor: Colors.amber.shade700,
                label: 'Ortalama puan',
                value: summary.averageRating?.toStringAsFixed(1) ?? '-',
              ),
            ),
          ],
        ),
        if (summary.hasHighNegativeRatio) ...[
          const SizedBox(height: 12),
          _WarningBanner(ratio: summary.negativeRatio),
        ],
        // Negatif detay artık hep açık - tıklama yok.
        if (hasNegativeDetail) ...[
          const SizedBox(height: 12),
          _NegativeDetail(summary: summary),
        ],
      ],
    );
  }
}

class _NegativeDetail extends StatelessWidget {
  const _NegativeDetail({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.negativeTrend.isNotEmpty) ...[
            Row(
              children: [
                Text('Negatif yorum trendi', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (summary.isNegativeTrendRising != null)
                  _TrendBadge(rising: summary.isNegativeTrendRising!),
              ],
            ),
            const SizedBox(height: 16),
            NegativeTrendChart(data: summary.negativeTrend),
            const SizedBox(height: 20),
          ],
          if (summary.recurringComplaints.isNotEmpty) ...[
            Text('Tekrar eden şikayetler', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in summary.recurringComplaints)
                  _ComplaintChip(complaint: c),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.rising});

  final bool rising;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = rising ? _Warn.color : scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rising ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          rising ? 'Artıyor' : 'Azalıyor',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ComplaintChip extends StatelessWidget {
  const _ComplaintChip({required this.complaint});

  final RecurringComplaint complaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _Warn.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            complaint.keyword,
            style: const TextStyle(color: _Warn.onSurface),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _Warn.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${complaint.count}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.tinted = false,
    this.tintColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool tinted;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Artık hiçbir kart tıklanabilir değil - saf gösterge.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? tintColor : scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tinted ? _Warn.onSurface : scheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tinted
                      ? _Warn.onSurface.withValues(alpha: 0.75)
                      : Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Warn.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: _Warn.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Negatif yorum oranı %${ratio.toStringAsFixed(0)} '
              '- eşik değerin üzerinde.',
              style: const TextStyle(color: _Warn.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentTasksSection extends StatelessWidget {
  const _UrgentTasksSection({
    required this.urgentAsync,
    required this.onSeeAll,
  });

  final AsyncValue<List<ActionItem>> urgentAsync;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return urgentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bekleyen görevler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('Tümünü gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final task in tasks)
              _UrgentTaskCard(task: task, onTap: onSeeAll),
          ],
        );
      },
    );
  }
}

class _UrgentTaskCard extends StatelessWidget {
  const _UrgentTaskCard({required this.task, required this.onTap});

  final ActionItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = task.isOverdue ? _Warn.color : scheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: task.isOverdue
              ? _Warn.color.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            task.isOverdue
                ? Icons.warning_amber_outlined
                : Icons.pending_outlined,
            color: accent,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: task.dueDate != null
            ? Text(
                task.isOverdue
                    ? 'Gecikmiş - ${_formatDate(task.dueDate!)}'
                    : 'Son tarih: ${_formatDate(task.dueDate!)}',
                style: TextStyle(
                  color: task.isOverdue ? _Warn.color : null,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
        onTap: onTap,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: _Warn.color),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}