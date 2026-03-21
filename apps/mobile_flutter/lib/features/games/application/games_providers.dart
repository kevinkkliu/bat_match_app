import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/game_summary.dart';
import '../data/games_repository.dart';

final Provider<GamesRepository> gamesRepositoryProvider =
    Provider<GamesRepository>((Ref ref) {
  return GamesRepository(ref.watch(dioProvider));
});

final StateProvider<GamesFeedQuery> gamesFeedQueryProvider =
    StateProvider<GamesFeedQuery>((Ref ref) {
  return const GamesFeedQuery();
});

final FutureProvider<PaginatedGames<GameSummary>> gamesListProvider =
    FutureProvider<PaginatedGames<GameSummary>>((Ref ref) async {
  final GamesFeedQuery query = ref.watch(gamesFeedQueryProvider);
  return ref.watch(gamesRepositoryProvider).fetchGames(query: query);
});

final FutureProviderFamily<GameDetail, String> gameDetailProvider =
    FutureProvider.family<GameDetail, String>((Ref ref, String gameId) async {
  return ref.watch(gamesRepositoryProvider).fetchGameDetail(gameId);
});
