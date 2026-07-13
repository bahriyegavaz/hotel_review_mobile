import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/api_auth_repository.dart';
import '../data/fake_auth_repository.dart';
import '../domain/auth_repository.dart';

/// Backend hazır olduğunda defaultValue'yu false yap.
/// Ya da kod değiştirmeden:
///   flutter run --dart-define=USE_FAKE_AUTH=false
const bool useFakeAuth = bool.fromEnvironment(
  'USE_FAKE_AUTH',
  defaultValue: true,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);

  if (useFakeAuth) {
    return FakeAuthRepository(storage);
  }

  final dio = ref.watch(dioProvider);
  return ApiAuthRepository(dio, storage);
});