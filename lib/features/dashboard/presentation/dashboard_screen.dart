import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/widget/loading_skeleton.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/app_drawer.dart';
import '../../action_items/domain/action_item.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_preview_providers.dart';
import 'dashboard_providers.dart';
import 'negative_trend_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _negativeExpanded = false;

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
        icon: const Icon(LucideIcons.message_square_plus),
        label: const Text('Yorum Ekle'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              _GreetingHeader(name: user?.fullName),
              const SizedBox(height: 24),
              summaryAsync.when(
                loading: () => const DashboardSkeleton(),
                error: (error, _) => _SummaryError(
                  message: error is DashboardFailure
                      ? error.message
                      : 'Özet veriler yüklenemedi.',
                  onRetry: () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                ),
                data: (summary) => _SummaryCards(
                  summary: summary,
                  negativeExpanded: _negativeExpanded,
                  onToggleNegative: () => setState(
                    () => _negativeExpanded = !_negativeExpanded,
                  ),
                  onOpenActions: () => context.push(AppRoutes.actionItems),
                ),
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
    );
  }
}

/// Selamlama + tarih. Solda menü butonu (drawer'ı açar).
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final displayName = name ?? '-';

    return Row(
      children: [
        // Drawer'ı açan menü butonu. Builder şart: Scaffold.of için
        // Scaffold'un içindeki bir context gerekiyor.
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            tooltip: 'Menü',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(now.hour)},',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatDate(now),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _greeting(int hour) {
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    const days = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.summary,
    required this.negativeExpanded,
    required this.onToggleNegative,
    required this.onOpenActions,
  });

  final DashboardSummary summary;
  final bool negativeExpanded;
  final VoidCallback onToggleNegative;
  final VoidCallback onOpenActions;

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
                trailing: Icon(
                  LucideIcons.chevron_right,
                  color: Theme.of(context).hintColor,
                  size: 20,
                ),
                onTap: onOpenActions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.frown,
                iconColor: scheme.error,
                label: 'Negatif yorum',
                value: '${summary.negativeReviewCount}',
                tinted: true,
                tintColor: scheme.errorContainer,
                trailing: hasNegativeDetail
                    ? Icon(
                        negativeExpanded
                            ? LucideIcons.chevron_up
                            : LucideIcons.chevron_down,
                        color: scheme.error,
                        size: 20,
                      )
                    : null,
                onTap: hasNegativeDetail ? onToggleNegative : null,
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
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: negativeExpanded
              ? _NegativeDetail(summary: summary)
              : const SizedBox.shrink(),
        ),
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
    final color = rising ? scheme.error : scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rising ? LucideIcons.trending_up : LucideIcons.trending_down,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            complaint.keyword,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${complaint.count}',
              style: TextStyle(
                color: scheme.onError,
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
    this.trailing,
    this.onTap,
    this.tinted = false,
    this.tintColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool tinted;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? tintColor : scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: AppTheme.softShadow(scheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: content,
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangle_alert, color: scheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Negatif yorum oranı %${ratio.toStringAsFixed(0)} '
              '- eşik değerin üzerinde.',
              style: TextStyle(color: scheme.onErrorContainer),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: task.isOverdue
              ? scheme.error.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (task.isOverdue ? scheme.error : scheme.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            task.isOverdue ? LucideIcons.triangle_alert : LucideIcons.clock,
            color: task.isOverdue ? scheme.error : scheme.primary,
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
                  color: task.isOverdue ? scheme.error : null,
                  fontSize: 12,
                ),
              )
            : null,
        trailing:
            Icon(LucideIcons.chevron_right, color: Theme.of(context).hintColor),
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
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Özet yükleniyor...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.cloud_off,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
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