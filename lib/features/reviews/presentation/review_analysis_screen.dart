import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';
import 'review_widgets.dart';

/// Yorum Detayı ekranındaki "Detaylı Analiz" ile açılır - AI'ın yorumu
/// cümle cümle böldüğü ABSA (Aspect-Based Sentiment Analysis) kırılımını
/// gösterir. Özet ekranından ayrı tutuyoruz çünkü çoğu kullanıcı sadece
/// genel özeti görmek istiyor; cümle cümle kırılım isteyen bilinçli olarak
/// buraya geliyor.
class ReviewAnalysisScreen extends ConsumerWidget {
  const ReviewAnalysisScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reviewDetailProvider(reviewId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detaylı Analiz')),
      body: detailAsync.when(
        loading: () => const ListSkeleton(itemCount: 3),
        error: (error, _) => _ErrorView(
          message: error is ReviewFailure
              ? error.message
              : 'Analiz yüklenemedi.',
          onRetry: () => ref.invalidate(reviewDetailProvider(reviewId)),
        ),
        data: (detail) => detail.clauseAnalyses.isEmpty
            ? const EmptyState(
                icon: Icons.psychology_outlined,
                title: 'AI analizi henüz yok',
                message: 'Bu yorum için henüz bir analiz sonucu üretilmedi.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: detail.clauseAnalyses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _ClauseCard(clause: detail.clauseAnalyses[index]),
              ),
      ),
    );
  }
}

class _ClauseCard extends StatelessWidget {
  const _ClauseCard({required this.clause});

  final ReviewClauseAnalysis clause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${clause.clauseText}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SentimentBadge(sentiment: clause.sentiment),
                _Tag(icon: Icons.label_outline, label: clause.categoryName),
                _Tag(icon: Icons.flag_outlined, label: clause.priority),
                _Tag(
                  icon: Icons.speed_outlined,
                  label: 'Skor ${clause.sentimentScore.toStringAsFixed(2)}',
                ),
              ],
            ),
            if (clause.suggestion != null &&
                clause.suggestion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                        clause.suggestion!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.hintColor),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
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
            FilledButton.tonal(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}
