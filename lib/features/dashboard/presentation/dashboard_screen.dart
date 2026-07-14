import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../action_items/domain/action_item.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_preview_providers.dart';
import 'dashboard_providers.dart';

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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(16),
          children: [
            _GreetingHeader(name: user?.fullName),
            const SizedBox(height: 24),
            summaryAsync.when(
              loading: () => const _LoadingCards(),
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
            // Bekleyen görev önizlemesi - sadece açık görev varsa gösterilir.
            _UrgentTasksSection(
              urgentAsync: urgentAsync,
              onSeeAll: () => context.push(AppRoutes.actionItems),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// Saate göre selamlama + günün tarihi. Kurumsal his katar.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
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
          name ?? '-',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(now),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
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

/// Dashboard'daki bekleyen görev önizlemesi.
/// En acil 1-2 görevi gösterir; "Tümünü gör" ile görevler ekranına geçer.
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
      // Aksiyon verisi yüklenirken sessizce boş dur - dashboard'un asıl
      // içeriği (KPI'lar) zaten görünüyor, burada spinner göstermeye gerek yok.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tasks) {
        // Açık görev yoksa bu bölümü hiç gösterme.
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bekleyen görevler',
                  style: Theme.of(context).textTheme.titleMedium,
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
      child: ListTile(
        leading: Icon(
          task.isOverdue ? Icons.warning_amber_outlined : Icons.pending_outlined,
          color: task.isOverdue ? scheme.error : scheme.primary,
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
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.today_outlined,
                label: 'Bugünkü yorum',
                value: '${summary.todayReviewCount}',
                color: scheme.primaryContainer,
                onColor: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.pending_actions_outlined,
                label: 'Açık görev',
                value: '${summary.openActionCount}',
                color: scheme.tertiaryContainer,
                onColor: scheme.onTertiaryContainer,
                // Sağ-ok: bu kart başka ekrana götürür (negatif kartın
                // aşağı-oku ise aynı ekranda detay açar - fark kasıtlı).
                trailing: Icon(
                  Icons.chevron_right,
                  color: scheme.onTertiaryContainer,
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
                icon: Icons.sentiment_dissatisfied_outlined,
                label: 'Negatif yorum',
                value: '${summary.negativeReviewCount}',
                color: scheme.errorContainer,
                onColor: scheme.onErrorContainer,
                trailing: (summary.negativeTrend.isNotEmpty ||
                        summary.recurringComplaints.isNotEmpty)
                    ? Icon(
                        negativeExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: scheme.onErrorContainer,
                        size: 20,
                      )
                    : null,
                onTap: (summary.negativeTrend.isNotEmpty ||
                        summary.recurringComplaints.isNotEmpty)
                    ? onToggleNegative
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.star_outline,
                label: 'Ortalama puan',
                value: summary.averageRating?.toStringAsFixed(1) ?? '-',
                color: scheme.secondaryContainer,
                onColor: scheme.onSecondaryContainer,
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
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 12),
            _MiniBarChart(
              data: summary.negativeTrend,
              max: summary.maxTrendCount,
            ),
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

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.data, required this.max});

  final List<DailyNegativeCount> data;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const barAreaHeight = 90.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in data)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.count}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: barAreaHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: max == 0
                            ? 2
                            : (item.count / max * barAreaHeight)
                                .clamp(2.0, barAreaHeight),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weekday(item.date),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _weekday(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
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
    required this.label,
    required this.value,
    required this.color,
    required this.onColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color onColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: onColor, size: 24),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: onColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
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