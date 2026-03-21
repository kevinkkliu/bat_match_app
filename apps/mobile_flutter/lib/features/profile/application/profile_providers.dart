import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../data/profile_repository.dart';

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>((Ref ref) {
  return ProfileRepository(
    ref.watch(dioProvider),
    const FlutterSecureStorage(),
  );
});

final FutureProvider<ProfileSession> profileSessionProvider =
    FutureProvider<ProfileSession>((Ref ref) {
  return ref.watch(profileRepositoryProvider).loadSession();
});
