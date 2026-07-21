import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widget/app_drawer.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';

/// Kullanıcının gönderdiği yorumları listeler.
///
/// Üstte kategori filtresi: yorumlar AI analizindeki kategoriye göre
/// süzülebilir (Temizlik, Yemek, Personel...). Kategoriler ayrı bir
/// endpoint'ten değil, GELEN YORUMLARDAN türetiliyor - böylece boş
/// kategori görünmez ve ekstra istek gerekmez.
class ReviewsListScreen extends ConsumerStatefulWidget {
  const ReviewsListScreen({super.key});

  @override
  ConsumerState<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends ConsumerState<ReviewsListScreen> {
  /// Seçili kategori. null = Tümü.
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
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
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'Henüz yorum yok',
              message: 'Eklenen yorumlar burada listelenecek.',
            );
          }

          // Kategorileri yorumlardan türet (analizsiz yorumlar hariç).
          final categories = reviews
              .map((r) => r.analysis?.category)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();

          // Seçili kategoriye göre süz. null = hepsi.
          final filtered = _selectedCategory == null
              ? reviews
              : reviews
                  .where((r) => r.analysis?.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              if (categories.isNotEmpty)
                _CategoryFilter(
                  categories: categories,
                  selected: _selectedCategory,
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_outlined,
                        title: 'Bu kategoride yorum yok',
                        message:
                            '$_selectedCategory kategorisinde yorum bulunamadı.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(myReviewsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _ReviewCard(review: filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Üstteki yatay kategori filtresi. "Tümü" + yorumlardan türeyen kategoriler.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
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
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onChanged(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
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
            Row(
              children: [
                _StarRow(rating: review.rating),
                const Spacer(),
                if (review.analysis != null)
                  _SentimentBadge(sentiment: review.analysis!.sentiment),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium,
            ),
            if (review.analysis != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.label_outline,
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
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  review.guestName ?? 'İsimsiz',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: theme.hintColor),
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
          Icons.sentiment_satisfied_outlined,
        ),
      Sentiment.negative => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.sentiment_dissatisfied_outlined,
        ),
      Sentiment.neutral => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          Icons.sentiment_neutral_outlined,
        ),
      Sentiment.unknown => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          Icons.help_outline,
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