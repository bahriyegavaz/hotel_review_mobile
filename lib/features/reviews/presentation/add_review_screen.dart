import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/theme/app_theme.dart';
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
      final path = await ref.read(imagePickerServiceProvider).pickPhoto(source);
      // Kullanıcı iptal ettiyse path null gelir - bu hata değil, normal akış.
      if (path != null && mounted) {
        setState(() => _photoPath = path);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      // İzin reddi ile genel hatayı ayırıyoruz - kullanıcı ne yapacağını bilsin.
      // Not: iOS Simulator'de kamera yoktur, bu hata orada da tetiklenir.
      final message = switch (e.code) {
        'camera_access_denied' =>
          'Kamera izni verilmedi. Ayarlar\'dan izin verebilirsiniz.',
        'photo_access_denied' =>
          'Galeri izni verilmedi. Ayarlar\'dan izin verebilirsiniz.',
        _ => 'Fotoğraf seçilemedi.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
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
              leading: const Icon(LucideIcons.camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(PhotoSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.images),
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
            guestName: _guestNameController.text.trim(),
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
        ref.read(addReviewControllerProvider.notifier).reset();

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Yorumunuz kaydedildi. Teşekkür ederiz.'),
            ),
          );

        // Yorum kaydedildikten sonra kullanıcıya AI analizi GÖSTERMİYORUZ.
        // "Yorumunuz olumsuz bulundu" demek anlamsız - analiz yöneticiler için.
        if (context.canPop()) {
          context.pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Yorum'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
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
                  ),
                  // Domain kuralını doğrudan kullanıyoruz - tek kaynak.
                  validator: NewReview.validateComment,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'İsim Soyisim ',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return "İsim zorunludur.";
                    if (name.isNotEmpty && name.length < 2) {
                      return 'İsim en az 2 karakter olmalıdır.';
                    }
                    return null;
                  },
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
                    'Yorum kaydediliyor...',
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
        final selected = value <= rating;
        return IconButton(
          iconSize: 40,
          onPressed: enabled ? () => onChanged(value) : null,
          icon: AnimatedScale(
            scale: selected ? 1.0 : 0.86,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Icon(
              selected ? Icons.star : Icons.star_border,
              color: selected ? Colors.amber : null,
            ),
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
        icon: const Icon(LucideIcons.image_plus),
        label: const Text('Fotoğraf ekle (opsiyonel)'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
          icon: const Icon(LucideIcons.trash_2),
          label: const Text('Fotoğrafı kaldır'),
        ),
      ],
    );
  }
}