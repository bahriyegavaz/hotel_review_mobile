import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/services/image_picker_service.dart';
import '../data/api_review_repository.dart';
import '../data/fake_review_repository.dart';
import '../domain/review_repository.dart';
import '../domain/review.dart';

/// Backend hazır olduğunda defaultValue'yu false yap.
/// Ya da: flutter run --dart-define=USE_FAKE_REVIEWS=false
const bool useFakeReviews = bool.fromEnvironment(
  'USE_FAKE_REVIEWS',
  defaultValue: false,
);

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (useFakeReviews) {
    return FakeReviewRepository();
  }
  return ApiReviewRepository(ref.watch(dioProvider));
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
final myReviewsProvider = FutureProvider<List<Review>>((ref) {
  return ref.watch(reviewRepositoryProvider).getMyReviews();
});

/// Yorum detay ekranı: fotoğraflar ve cümle bazlı AI analizi id'ye göre çekilir.
final reviewDetailProvider =
    FutureProvider.family<ReviewDetail, String>((ref, id) {
  return ref.watch(reviewRepositoryProvider).getReviewDetail(id);
});