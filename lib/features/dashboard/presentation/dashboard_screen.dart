import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widget/app_drawer.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_hero.dart';
import 'dashboard_providers.dart';
import 'rating_trend_chart.dart';

/// Negatif/uyarı vurgusu için yumuşak kırmızı tonları.
class _Warn {
  _Warn._();
  static const Color color = Color(0xFFD96570);
  static const Color surface = Color(0xFFFCEDEE);
  static const Color onSurface = Color(0xFF8A3B43);
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardControllerProvider);

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
                child: summaryAsync.when(
                  loading: () => const _LoadingCards(),
                  error: (error, _) => _SummaryError(
                    message: error is DashboardFailure
                        ? error.message
                        : 'Özet veriler yüklenemedi.',
                    onRetry: () => ref
                        .read(dashboardControllerProvider.notifier)
                        .refresh(),
                  ),
                  data: (summary) => _SummarySection(summary: summary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KPI kartları + uyarı + trend + kategori + etiketler.
class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Açık renkli kartlar üstte - hero fotoğrafının üstünde
        // çizgileri kaybolmasın diye.
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.frown,
                iconColor: _Warn.color,
                label: 'Negatif yorum',
                value: '${summary.negativeReviewCount}',
                tinted: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: LucideIcons.star,
                iconColor: Colors.amber.shade600,
                label: 'Ortalama puan',
                value: summary.averageRating?.toStringAsFixed(1) ?? '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        if (summary.hasHighNegativeRatio) ...[
          const SizedBox(height: 16),
          _WarningBanner(ratio: summary.negativeRatio),
        ],
        if (summary.ratingTrend.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TrendCard(summary: summary),
        ],
        if (summary.categoryDistribution.isNotEmpty) ...[
          const SizedBox(height: 16),
          _CategoryDistributionCard(items: summary.categoryDistribution),
        ],
        if (summary.recurringComplaints.isNotEmpty) ...[
          const SizedBox(height: 16),
          _KeywordsCard(complaints: summary.recurringComplaints),
        ],
      ],
    );
  }
}

/// Kart görünümü: beyaz zemin, yumuşak gölge. Diğer bölümler bunu kullanır.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child}) : padding = null;

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Kritik uyarı: solda dikey renk çizgisi, kalın başlık, açıklama.
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: _Warn.surface,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol dikey vurgu çizgisi.
              Container(width: 4, color: _Warn.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: _Warn.color,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kritik Uyarı',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: _Warn.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Negatif yorum oranı %${ratio.toStringAsFixed(0)} '
                              '- eşik değerin üzerinde.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _Warn.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trend grafiği kendi kartında.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Puan Trendi (Son 7 Gün)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (summary.isRatingTrendDeclining != null)
                _TrendBadge(declining: summary.isRatingTrendDeclining!),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Günlük ortalama puan.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          RatingTrendChart(data: summary.recentRatingTrend),
        ],
      ),
    );
  }
}

/// Kategori başına yorum hacmi ve negatiflik oranı.
class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({required this.items});

  final List<CategoryDistributionItem> items;

  /// Dashboard bir özet - en fazla 6 kategori gösterilir.
  static const int _maxItems = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sorted = items.where((c) => c.reviewCount > 0).toList()
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    final topItems = sorted.take(_maxItems).toList();

    if (topItems.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Dağılımı',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'En çok yorum alan kategoriler ve negatiflik oranı.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          for (final item in topItems) ...[
            _CategoryRow(item: item),
            if (item != topItems.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item});

  final CategoryDistributionItem item;

  /// Negatiflik oranına göre renk: düşük mavi, orta amber, yüksek kırmızı.
  Color _ratioColor(ColorScheme scheme) {
    if (item.negativeRatio >= 50) return _Warn.color;
    if (item.negativeRatio >= 20) return Colors.amber.shade700;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _ratioColor(scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.categoryName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.reviewCount} yorum',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.negativeRatio / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '%${item.negativeRatio.toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Öne çıkan negatif etiketler kartı.
class _KeywordsCard extends StatelessWidget {
  const _KeywordsCard({required this.complaints});

  final List<RecurringComplaint> complaints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Öne Çıkan Negatif Etiketler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yorum analizine göre en çok şikayet edilen konular.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in complaints) _ComplaintChip(complaint: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.declining});

  final bool declining;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = declining ? _Warn.color : scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          declining ? Icons.trending_down : Icons.trending_up,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          declining ? 'Düşüyor' : 'Yükseliyor',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// "banyo (8)" - sayı parantez içinde.
class _ComplaintChip extends StatelessWidget {
  const _ComplaintChip({required this.complaint});

  final RecurringComplaint complaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _Warn.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_outline, size: 14, color: _Warn.color),
          const SizedBox(width: 6),
          Text(
            '${complaint.keyword} (${complaint.count})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _Warn.onSurface,
              fontWeight: FontWeight.w500,
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
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// true ise rakam/etiket soft kırmızı (negatif yorum kartı).
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = 20.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: scheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, color: iconColor),
              Padding(
                padding: const EdgeInsets.all(16),
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tinted ? _Warn.color : scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tinted
                            ? _Warn.color.withValues(alpha: 0.85)
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return _SectionCard(
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