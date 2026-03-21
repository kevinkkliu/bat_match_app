import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_summary.dart';
import '../../games/application/games_providers.dart';

final FutureProvider<List<GameSummary>> joinedGamesProvider =
    FutureProvider<List<GameSummary>>((Ref ref) async {
  return ref.watch(gamesRepositoryProvider).fetchJoinedGames();
});

final FutureProvider<List<GameSummary>> createdGamesProvider =
    FutureProvider<List<GameSummary>>((Ref ref) async {
  return ref.watch(gamesRepositoryProvider).fetchCreatedGames();
});
