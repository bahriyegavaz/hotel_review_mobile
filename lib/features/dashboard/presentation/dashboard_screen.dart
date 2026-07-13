import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardControllerProvider);

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
          // Liste kısa olsa bile pull-to-refresh çalışsın diye.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hoş geldiniz, ${user?.fullName ?? '-'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Özet yüklenemese bile aşağıdaki navigasyon çalışmaya devam eder.
            summaryAsync.when(
              loading: () => const _LoadingCards(),
              error: (error, _) => _SummaryError(
                message: error is DashboardFailure
                    ? error.message
                    : 'Özet veriler yüklenemedi.',
                onRetry: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
              ),
              data: (summary) => _SummaryCards(summary: summary),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('Görevlerim'),
                subtitle: const Text('Departmanınıza atanan aksiyonlar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.actionItems),
              ),
            ),
            // FAB'ın son kartı örtmemesi için.
            const SizedBox(height: 80),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.star_outline,
                label: 'Ortalama puan',
                // Backend göndermezse tire göster, 0.0 değil.
                // "Veri yok" ile "puan sıfır" farklı şeylerdir.
                value: summary.averageRating?.toStringAsFixed(1) ?? '-',
                color: scheme.secondaryContainer,
                onColor: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
        if (summary.hasHighNegativeRatio) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Negatif yorum oranı '
                    '%${summary.negativeRatio.toStringAsFixed(0)} '
                    '- eşik değerin üzerinde.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onColor, size: 24),
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
  }
}

/// Yüklenirken kartların yerini tutar. Sabit yükseklik veriyoruz ki
/// veri gelince layout zıplamasın.
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
        borderRadius: BorderRadius.circular(12),
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