import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/auth_required_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../application/my_games_providers.dart';

class MyGamesPage extends ConsumerWidget {
  const MyGamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfileSession> sessionAsync =
        ref.watch(profileSessionProvider);

    if (sessionAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (sessionAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Games')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SectionCard(
            title: 'My Games',
            subtitle: 'Could not load your account state.',
            child: Text(sessionAsync.error.toString()),
          ),
        ),
      );
    }

    final ProfileSession session = sessionAsync.requireValue;
    if (!session.hasServerIdentity) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Games')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AuthRequiredCard(
            title: 'Your schedule is available after sign-in',
            message:
                'Guests can browse live matches, but joined and created games are only available for signed-in accounts.',
            onSignInPressed: () => context.go(AppRoutePaths.profile),
          ),
        ),
      );
    }

    final AsyncValue<List<GameSummary>> joinedAsync =
        ref.watch(joinedGamesProvider);
    final AsyncValue<List<GameSummary>> createdAsync =
        ref.watch(createdGamesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Games'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: 'Joined'),
              Tab(text: 'Created'),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFF6F1E8),
                Color(0xFFF4F7EF),
              ],
            ),
          ),
          child: Column(
            children: <Widget>[
              _MyGamesHero(
                joinedCount: joinedAsync.valueOrNull?.length,
                createdCount: createdAsync.valueOrNull?.length,
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _GamesTab(
                      gamesAsync: joinedAsync,
                      emptyTitle: 'No joined games yet',
                      emptySubtitle:
                          'Your approved or upcoming joined games will appear here.',
                      emptyBody: 'Tap a game in Discover to join it.',
                      refresh: () async {
                        ref.invalidate(joinedGamesProvider);
                        await ref.read(joinedGamesProvider.future);
                      },
                      gameTileSubtitle: 'Joined',
                    ),
                    _GamesTab(
                      gamesAsync: createdAsync,
                      emptyTitle: 'No created games yet',
                      emptySubtitle:
                          'Games you host will appear here once you publish them.',
                      emptyBody: 'Create a game to see it in this list.',
                      refresh: () async {
                        ref.invalidate(createdGamesProvider);
                        await ref.read(createdGamesProvider.future);
                      },
                      gameTileSubtitle: 'Created',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyGamesHero extends StatelessWidget {
  const _MyGamesHero({
    required this.joinedCount,
    required this.createdCount,
  });

  final int? joinedCount;
  final int? createdCount;

  @override
  Widget build(BuildContext context) {
    final String joinedLabel = joinedCount == null ? '...' : '$joinedCount';
    final String createdLabel = createdCount == null ? '...' : '$createdCount';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF284C36),
              Color(0xFF101F18),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF284C36).withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _HeroBadge(
                    label: 'Live API',
                    icon: Icons.cloud_done_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Your games at a glance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track what you joined and what you host without digging through separate screens.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HeroChip(
                    label: '$joinedLabel joined',
                    icon: Icons.playlist_add_check_rounded,
                  ),
                  _HeroChip(
                    label: '$createdLabel hosting',
                    icon: Icons.meeting_room_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  const _GamesTab({
    required this.gamesAsync,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyBody,
    required this.refresh,
    required this.gameTileSubtitle,
  });

  final AsyncValue<List<GameSummary>> gamesAsync;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyBody;
  final Future<void> Function() refresh;
  final String gameTileSubtitle;

  @override
  Widget build(BuildContext context) {
    return AsyncStateView(
      isLoading: gamesAsync.isLoading,
      errorMessage: gamesAsync.hasError ? gamesAsync.error.toString() : null,
      child: gamesAsync.maybeWhen(
        data: (List<GameSummary> games) {
          if (games.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  SectionCard(
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                    child: Text(emptyBody),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: games.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return SectionCard(
                    title: '$gameTileSubtitle games',
                    subtitle: 'Pulled from the live API.',
                    child: Text(
                      gameTileSubtitle == 'Joined'
                          ? 'Approved and upcoming games you are participating in.'
                          : 'Games you host and manage.',
                    ),
                  );
                }

                final GameSummary game = games[index - 1];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pushNamed(
                    AppRouteNames.gameDetail,
                    pathParameters: <String, String>{'gameId': game.id},
                  ),
                  child: _GameTile(
                    game: game,
                    subtitle: gameTileSubtitle,
                  ),
                );
              },
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.subtitle,
  });

  final GameSummary game;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      title: game.title,
      subtitle: '${game.city} · ${game.district}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  game.venueName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF173321),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _PriceBadge(fee: game.fee),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaPill(
                icon: Icons.schedule_rounded,
                label:
                    '${_formatDate(game.startAt)} · ${_formatTime(game.startAt)}',
              ),
              _MetaPill(
                icon: Icons.people_alt_rounded,
                label: '${game.availableSpots}/${game.capacity} spots left',
              ),
              _MetaPill(
                icon: Icons.flag_rounded,
                label: switch (game.status) {
                  'OPEN' => 'Open',
                  'FULL' => 'Full',
                  'CANCELLED' => 'Cancelled',
                  'COMPLETED' => 'Completed',
                  _ => game.status,
                },
              ),
              _MetaPill(
                icon: subtitle == 'Created'
                    ? Icons.rule_folder_rounded
                    : Icons.playlist_add_check_rounded,
                label: subtitle == 'Created' ? 'Host view' : 'Player view',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            game.venueAddress,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF55655B),
              height: 1.45,
            ),
          ),
          if (subtitle == 'Created') ...<Widget>[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.pushNamed(
                  AppRouteNames.gameRequests,
                  pathParameters: <String, String>{
                    'gameId': game.id,
                  },
                ),
                icon: const Icon(Icons.rule_folder_outlined),
                label: const Text('Manage requests'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.fee,
  });

  final int fee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'NT\$$fee',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E6B42),
            ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF5A6A60)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF55655B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
