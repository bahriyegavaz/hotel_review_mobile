import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';

sealed class AddReviewState {
  const AddReviewState();
}

class AddReviewIdle extends AddReviewState {
  const AddReviewIdle();
}

class AddReviewSubmitting extends AddReviewState {
  const AddReviewSubmitting();
}

/// Başarı durumunda kaydedilen yorumu taşıyoruz - AI analiz sonucunu
/// kullanıcıya gösterebilmek için (rapor: "AI sonucu kaydedilir").
class AddReviewSuccess extends AddReviewState {
  const AddReviewSuccess(this.review);
  final Review review;
}

class AddReviewFailed extends AddReviewState {
  const AddReviewFailed(this.message);
  final String message;
}

class AddReviewController extends Notifier<AddReviewState> {
  @override
  AddReviewState build() => const AddReviewIdle();

  Future<void> submit(NewReview review) async {
    state = const AddReviewSubmitting();
    try {
      final saved = await ref.read(reviewRepositoryProvider).createReview(review);
      state = AddReviewSuccess(saved);
    } on ReviewFailure catch (e) {
      state = AddReviewFailed(e.message);
    } catch (_) {
      state = const AddReviewFailed('Beklenmeyen bir hata oluştu.');
    }
  }

  /// Ekran kapanırken ya da kullanıcı yeni yorum yazmaya başlarken.
  void reset() => state = const AddReviewIdle();
}

final addReviewControllerProvider =
    NotifierProvider<AddReviewController, AddReviewState>(
  AddReviewController.new,
);