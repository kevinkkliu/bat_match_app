import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../games/application/games_providers.dart';
import '../../games/data/games_repository.dart';

final FutureProviderFamily<List<JoinRequestSummary>, String>
    gameJoinRequestsProvider =
    FutureProvider.family<List<JoinRequestSummary>, String>(
  (Ref ref, String gameId) async {
    return ref.watch(gamesRepositoryProvider).fetchGameJoinRequests(gameId);
  },
);
