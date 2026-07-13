import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../auth/data/auth_dto.dart' show ApiResponse;
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_dto.dart';

/// Gerçek .NET backend'e konuşan implementasyon.
class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._dio);

  final Dio _dio;

  /// Rapor bölüm 12: "Dosyalar için boyut ve uzantı kontrolü yapılmalı."
  /// Backend de kontrol edecek, ama kullanıcıya hızlı geri bildirim vermek
  /// ve gereksiz upload yapmamak için istemcide de kontrol ediyoruz.
  static const int maxPhotoBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png'};

  @override
  Future<Review> createReview(NewReview review) async {
    try {
      // Fotoğraf varsa multipart/form-data, yoksa yine FormData gönderiyoruz
      // ki backend tek bir endpoint ile iki durumu da karşılayabilsin.
      final formData = FormData.fromMap({
        'comment': review.comment,
        'rating': review.rating,
        if (review.guestName != null && review.guestName!.isNotEmpty)
          'guestName': review.guestName,
        'source': ReviewSource.mobile.apiValue,
      });

      if (review.photoPath != null) {
        formData.files.add(
          MapEntry('photo', await _buildPhotoFile(review.photoPath!)),
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/mobile/reviews-with-photo',
        data: formData,
      );

      final body = response.data;
      if (body == null) throw const UnknownReviewFailure();

      final apiResponse = ApiResponse<ReviewDto>.fromJson(
        body,
        ReviewDto.fromJson,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw UnknownReviewFailure(apiResponse.message);
      }

      return apiResponse.data!.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<Review>> getMyReviews() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reviews');
      final body = response.data;
      if (body == null) return const [];

      // Liste dönen endpointlerde "data" bir array olduğu için
      // ApiResponse<T> yerine elle parse ediyoruz.
      final rawList = body['data'];
      if (rawList is! List) return const [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => ReviewDto.fromJson(json).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MultipartFile> _buildPhotoFile(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw const ReviewFileFailure('Seçilen fotoğraf bulunamadı.');
    }

    final extension = p.extension(path).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw const ReviewFileFailure(
        'Sadece JPG ve PNG formatları destekleniyor.',
      );
    }

    final length = await file.length();
    if (length > maxPhotoBytes) {
      throw const ReviewFileFailure('Fotoğraf 5 MB\'tan küçük olmalıdır.');
    }

    return MultipartFile.fromFile(path, filename: p.basename(path));
  }

  ReviewFailure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ReviewNetworkFailure();
    }
    if (e.response?.statusCode == 400) {
      return ReviewValidationFailure(
        e.response?.data is Map
            ? (e.response!.data['message'] as String? ?? 'Geçersiz veri.')
            : 'Geçersiz veri.',
      );
    }
    if (e.response?.statusCode == 413) {
      return const ReviewFileFailure('Fotoğraf çok büyük.');
    }
    return UnknownReviewFailure(e.message);
  }
}