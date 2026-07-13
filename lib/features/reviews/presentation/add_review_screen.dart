import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/image_picker_service.dart';
import '../domain/review.dart';
import 'add_review_controller.dart';
import 'review_providers.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  const AddReviewScreen({super.key});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _guestNameController = TextEditingController();

  int _rating = 0;
  String? _photoPath;

  @override
  void dispose() {
    _commentController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(PhotoSource source) async {
    try {
      final path =
          await ref.read(imagePickerServiceProvider).pickPhoto(source);
      // Kullanıcı iptal ettiyse path null gelir - hiçbir şey yapma.
      if (path != null && mounted) {
        setState(() => _photoPath = path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilemedi.')),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(PhotoSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(PhotoSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final ratingError = NewReview.validateRating(_rating == 0 ? null : _rating);
    if (ratingError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ratingError)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    ref.read(addReviewControllerProvider.notifier).submit(
          NewReview(
            comment: _commentController.text.trim(),
            rating: _rating,
            guestName: _guestNameController.text.trim().isEmpty
                ? null
                : _guestNameController.text.trim(),
            photoPath: _photoPath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReviewControllerProvider);
    final isSubmitting = state is AddReviewSubmitting;

    ref.listen<AddReviewState>(addReviewControllerProvider, (previous, next) {
      if (next is AddReviewFailed) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
      if (next is AddReviewSuccess) {
        _showAnalysisDialog(next.review);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Yorum')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Puan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _StarRating(
                  rating: _rating,
                  enabled: !isSubmitting,
                  onChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _commentController,
                  enabled: !isSubmitting,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Yorumunuz',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  // Domain kuralını doğrudan kullanıyoruz - tek kaynak.
                  validator: NewReview.validateComment,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestNameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Misafir adı (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                _PhotoPicker(
                  photoPath: _photoPath,
                  enabled: !isSubmitting,
                  onPick: _showPhotoSourceSheet,
                  onRemove: () => setState(() => _photoPath = null),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gönder'),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Yorum kaydediliyor ve analiz ediliyor...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kaydedilen yorumun AI analizini gösterir.
  /// Rapor bölüm 9'daki çıktı alanları: sentiment, category, keywords, suggestion.
  void _showAnalysisDialog(Review review) {
    final analysis = review.analysis;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yorum kaydedildi'),
        content: analysis == null
            ? const Text('Analiz sonucu henüz hazır değil.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnalysisRow('Duygu', analysis.sentiment.label),
                  _AnalysisRow('Kategori', analysis.category),
                  _AnalysisRow('Kelimeler', analysis.keywords.join(', ')),
                  if (analysis.suggestion != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Öneri',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(analysis.suggestion!),
                  ],
                ],
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(addReviewControllerProvider.notifier).reset();
              if (context.canPop()) context.pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.onChanged,
    required this.enabled,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          iconSize: 40,
          onPressed: enabled ? () => onChanged(value) : null,
          icon: Icon(
            value <= rating ? Icons.star : Icons.star_border,
            color: value <= rating ? Colors.amber : null,
          ),
        );
      }),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoPath,
    required this.onPick,
    required this.onRemove,
    required this.enabled,
  });

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (photoPath == null) {
      return OutlinedButton.icon(
        onPressed: enabled ? onPick : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Fotoğraf ekle (opsiyonel)'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(photoPath!),
            height: 200,
            fit: BoxFit.cover,
            // Dosya bir şekilde silinmişse çökmesin.
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Text('Fotoğraf yüklenemedi')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Fotoğrafı kaldır'),
        ),
      ],
    );
  }
}

