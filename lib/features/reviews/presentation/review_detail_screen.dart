import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widget/empty_state.dart';
import '../../../core/widget/loading_skeleton.dart';
import '../../action_items/presentation/action_items_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';
import 'review_widgets.dart';

/// Tek bir yorumun detayı: fotoğraflar + AI'ın cümle cümle çıkardığı
/// ABSA (Aspect-Based Sentiment Analysis) sonuçları.
///
/// GET /api/reviews listesinde bu veriler yok - sadece
/// GET /api/reviews/{id} ile geliyor, o yüzden ayrı bir ekran ve ayrı
/// bir istek (reviewDetailProvider) gerekiyor.
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reviewDetailProvider(reviewId));

    return Scaffold(
      appBar: AppBar(title: const Text('Yorum Detayı')),
      body: detailAsync.when(
        loading: () => const ListSkeleton(itemCount: 3),
        error: (error, _) => _ErrorView(
          message: error is ReviewFailure
              ? error.message
              : 'Yorum detayı yüklenemedi.',
          onRetry: () => ref.invalidate(reviewDetailProvider(reviewId)),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});

  final ReviewDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canManage = ref.watch(currentUserProvider)?.canViewAllDepartments ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StarRow(rating: detail.rating),
                    const Spacer(),
                    Icon(Icons.schedule, size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(detail.reviewDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(detail.comment, style: theme.textTheme.bodyMedium),
                for (final attachment in detail.attachments) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: attachment.fileUrl,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      detail.guestName ?? 'İsimsiz',
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
        // Admin/Manager, AI'ın otomatik oluşturduğu aksiyonlara ek olarak
        // bu yoruma aksiyon ekleyebilir (POST /api/action-items - "Web Panel
        // (Angular)" etiketli ama erişim rol bazlı, mobil de kullanabiliyor).
        if (canManage) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              // AI zaten bu yorum için bir aksiyon oluşturduysa (negatif
              // cümleden), formu onun departmanı ve önerisiyle önceden
              // doldur - admin sıfırdan yazmak zorunda kalmasın. Liste
              // henüz yüklenmediyse (.future) bekleriz, aksi halde
              // varsayılan boş kalırdı.
              final items = await ref.read(actionItemsControllerProvider.future);
              final matchingItems = items.where((i) => i.reviewId == detail.id);
              final existingForReview = matchingItems.isEmpty
                  ? null
                  : matchingItems.first;
              final suggestions = detail.overallAnalysis?.suggestions;
              final defaultSuggestion = (suggestions == null || suggestions.isEmpty)
                  ? null
                  : suggestions.first;

              if (!context.mounted) return;
              _showAddActionItemSheet(
                context,
                ref,
                detail.id,
                initialTitle: existingForReview?.title ?? defaultSuggestion,
                initialDepartmentId: existingForReview?.departmentId,
                initialDepartmentName: existingForReview?.departmentName,
              );
            },
            icon: const Icon(Icons.add_task_outlined, size: 18),
            label: const Text('Aksiyon Ekle'),
          ),
        ],
        if (detail.overallAnalysis != null) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Analizi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail.clauseAnalyses.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      context.push('${AppRoutes.reviews}/${detail.id}/analysis'),
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: const Text('Detaylı Analiz'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _OverallAnalysisCard(analysis: detail.overallAnalysis!),
        ] else ...[
          const SizedBox(height: 20),
          const EmptyState(
            icon: Icons.psychology_outlined,
            title: 'AI analizi henüz yok',
            message: 'Bu yorum için henüz bir analiz sonucu üretilmedi.',
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

void _showAddActionItemSheet(
  BuildContext context,
  WidgetRef ref,
  String reviewId, {
  String? initialTitle,
  String? initialDepartmentId,
  String? initialDepartmentName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AddActionItemSheet(
      reviewId: reviewId,
      initialTitle: initialTitle,
      initialDepartmentId: initialDepartmentId,
      initialDepartmentName: initialDepartmentName,
    ),
  );
}

/// Admin/Manager'ın bir yoruma aksiyon eklediği form.
///
/// Departman listesi ayrı bir /api/departments çağrısı yapmıyor - o
/// endpoint şu an otel bazlı filtrelenmediği için aynı departman adını
/// birden çok otelden tekrar tekrar dönüyor (gerçek bir backend hatası).
/// Bunun yerine action_items ekranındaki departman seçici için zaten
/// kullanılan, doğru otele göre sınırlı availableDepartmentsProvider'ı
/// paylaşıyoruz.
class _AddActionItemSheet extends ConsumerStatefulWidget {
  const _AddActionItemSheet({
    required this.reviewId,
    this.initialTitle,
    this.initialDepartmentId,
    this.initialDepartmentName,
  });

  final String reviewId;

  /// AI'ın bu yorum için ürettiği öneri (ampul ikonlu metin) - admin
  /// sıfırdan yazmasın diye başlığa önceden dolduruluyor.
  final String? initialTitle;

  /// AI zaten bu yorum için bir aksiyon oluşturduysa onun departmanı -
  /// admin genelde AI'ın seçtiği departmanla devam eder.
  final String? initialDepartmentId;
  final String? initialDepartmentName;

  @override
  ConsumerState<_AddActionItemSheet> createState() =>
      _AddActionItemSheetState();
}

class _AddActionItemSheetState extends ConsumerState<_AddActionItemSheet> {
  late final _titleController = TextEditingController(
    text: widget.initialTitle ?? '',
  );
  late String? _departmentId = widget.initialDepartmentId;
  late String? _departmentName = widget.initialDepartmentName;
  DateTime? _dueDate;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit(List<(String id, String name)> departments) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _departmentId == null) return;

    setState(() => _submitting = true);

    final errorMessage = await ref
        .read(actionItemsControllerProvider.notifier)
        .createManualActionItem(
          reviewId: widget.reviewId,
          departmentId: _departmentId!,
          departmentName: _departmentName!,
          title: title,
          dueDate: _dueDate,
        );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Aksiyon eklendi.'),
          backgroundColor: errorMessage != null
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(availableDepartmentsProvider);
    final canSubmit =
        !_submitting && _departmentId != null && _titleController.text.trim().isNotEmpty;

    // Önceden seçtiğimiz departman, şu an yüklü departman listesinde yoksa
    // (ör. sayfa ilk açıldığında liste henüz gelmediyse) dropdown'a boş
    // değer geçiyoruz - aksi halde "value doesn't match any item" hatası
    // fırlatır.
    final dropdownValue = departments.any((d) => d.$1 == _departmentId)
        ? _departmentId
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksiyon Ekle',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: dropdownValue,
              decoration: const InputDecoration(labelText: 'Departman'),
              items: [
                for (final (id, name) in departments)
                  DropdownMenuItem(value: id, child: Text(name)),
              ],
              onChanged: (value) => setState(() {
                _departmentId = value;
                _departmentName = departments
                    .firstWhere((d) => d.$1 == value)
                    .$2;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Aksiyon başlığı',
                hintText: 'Örn. Bar servis noktası sayısı artırılsın',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'Son tarih seçilmedi (opsiyonel)'
                        : 'Son tarih: ${_DetailBody._formatDate(_dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: _pickDueDate,
                  child: const Text('Tarih Seç'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? () => _submit(departments) : null,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cümle bazlı analizlerin tek bir özette birleştirilmiş hali: tahmin
/// edilen departman/kategori, AI güven oranı, öne çıkan şikayet cümlesi ve
/// önerilen departman aksiyonu.
class _OverallAnalysisCard extends StatelessWidget {
  const _OverallAnalysisCard({required this.analysis});

  final ReviewOverallAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryCategory = analysis.categories.isNotEmpty
        ? analysis.categories.first
        : 'Genel';
    final secondaryCategories = analysis.categories.skip(1).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SentimentBadge(sentiment: analysis.sentiment),
                const Spacer(),
                _Tag(icon: Icons.flag_outlined, label: analysis.priority),
                const SizedBox(width: 8),
                _Tag(
                  icon: Icons.speed_outlined,
                  label: 'Skor ${analysis.averageScore.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel('Tahmin Edilen Departman / Kategori'),
            const SizedBox(height: 4),
            Text(
              primaryCategory,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (secondaryCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in secondaryCategories)
                    _Tag(icon: Icons.label_outline, label: category),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _SectionLabel('Model Güven / Eminlik Oranı'),
            const SizedBox(height: 4),
            Text(
              '%${(analysis.confidence * 100).round()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (analysis.highlightedClause != null) ...[
              const SizedBox(height: 16),
              _SectionLabel('Özetlenmiş Müşteri Şikayeti'),
              const SizedBox(height: 4),
              Text(
                '"${analysis.highlightedClause}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (analysis.suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel('Önerilen Departman Aksiyonu'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final suggestion in analysis.suggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
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
                                suggestion,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
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

/// Analiz kartındaki alt başlıklar (örn. "Model Güven / Eminlik Oranı").
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).hintColor,
        letterSpacing: 0.4,
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
