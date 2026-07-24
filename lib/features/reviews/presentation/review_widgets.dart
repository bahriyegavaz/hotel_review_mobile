import 'package:flutter/material.dart';

import '../domain/review.dart';

/// 1-5 yıldız gösterimi. Liste kartında ve detay ekranında ortak kullanılır.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating});

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

/// AI duygu durumu rozeti. Liste kartında ve detay ekranında ortak kullanılır.
class SentimentBadge extends StatelessWidget {
  const SentimentBadge({super.key, required this.sentiment});

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
