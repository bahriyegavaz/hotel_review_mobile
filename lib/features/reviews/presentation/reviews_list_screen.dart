import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widget/app_drawer.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';

/// Kullanıcının gönderdiği yorumları listeler.
///
/// Salt okunur - buradan yorum düzenlenmez/silinmez (rapor bölüm 11 mobil
/// için sadece ekleme + listeleme istiyor). Yeni yorum "Yorum Ekle"den.
class ReviewsListScreen extends ConsumerWidget {
  const ReviewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Yorumlar')),
      body: reviewsAsync.when(
        loading: () => const ListSkeleton(),
        error: (error, _) => _ErrorView(
          message: error is ReviewFailure
              ? error.message
              : 'Yorumlar yüklenemedi.',
          onRetry: () => ref.invalidate(myReviewsProvider),
        ),
        data: (reviews) => reviews.isEmpty
            ? const EmptyState(
                icon: LucideIcons.message_square_text,
                title: 'Henüz yorum yok',
                message: 'Eklenen yorumlar burada listelenecek.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myReviewsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) =>
                      _ReviewCard(review: reviews[index]),
                ),
              ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: yıldızlar + analiz rozeti
            Row(
              children: [
                _StarRow(rating: review.rating),
                const Spacer(),
                if (review.analysis != null)
                  _SentimentBadge(sentiment: review.analysis!.sentiment),
              ],
            ),
            const SizedBox(height: 10),
            // Yorum metni
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium,
            ),
            // Kategori (analiz varsa)
            if (review.analysis != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    LucideIcons.tag,
                    size: 14,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.analysis!.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Alt satır: misafir adı + tarih
            Row(
              children: [
                Icon(LucideIcons.user, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  review.guestName ?? 'İsimsiz',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  _formatDate(review.reviewDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

/// Puanı yıldızlarla gösterir.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 18,
            color: i <= rating ? Colors.amber : Theme.of(context).hintColor,
          ),
      ],
    );
  }
}

/// Analiz duygu durumunu renkli rozet olarak gösterir.
class _SentimentBadge extends StatelessWidget {
  const _SentimentBadge({required this.sentiment});

  final Sentiment sentiment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (background, foreground, icon) = switch (sentiment) {
      Sentiment.positive => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          LucideIcons.smile,
        ),
      Sentiment.negative => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          LucideIcons.frown,
        ),
      Sentiment.neutral => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          LucideIcons.meh,
        ),
      Sentiment.unknown => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          LucideIcons.circle_question_mark,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            sentiment.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: foreground),
          ),
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
              LucideIcons.circle_alert,
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