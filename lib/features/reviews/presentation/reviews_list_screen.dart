import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widget/app_drawer.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';
import 'review_widgets.dart';

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
          final categories =
              reviews
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.reviews}/${review.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StarRow(rating: review.rating),
                  const Spacer(),
                  if (review.analysis != null)
                    SentimentBadge(sentiment: review.analysis!.sentiment),
                ],
              ),
              const SizedBox(height: 10),
              Text(review.comment, style: theme.textTheme.bodyMedium),
              if (review.photoUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: review.photoUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ],
              if (review.analysis != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 14, color: theme.hintColor),
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
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
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
