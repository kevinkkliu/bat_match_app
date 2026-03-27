import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/auth_required_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_callout.dart';
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
        appBar: AppBar(title: const Text('我的球局')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SectionCard(
            title: '我的球局',
            subtitle: '無法載入你的帳號狀態。',
            child: Text(sessionAsync.error.toString()),
          ),
        ),
      );
    }

    final ProfileSession session = sessionAsync.requireValue;
    if (!session.hasServerIdentity) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的球局')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AuthRequiredCard(
            title: '登入後才會顯示你的行程',
            message: '訪客可以先瀏覽公開球局；登入後才能看到已加入與我建立的球局，並追蹤報名狀態。',
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
          title: const Text('我的球局'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: '已加入'),
              Tab(text: '我建立的'),
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
                joinedActiveCount: _activeGameCount(joinedAsync.valueOrNull),
                createdActiveCount: _activeGameCount(createdAsync.valueOrNull),
                joinedHistoryCount: _historyGameCount(joinedAsync.valueOrNull),
                createdHistoryCount:
                    _historyGameCount(createdAsync.valueOrNull),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _GamesTab(
                      gamesAsync: joinedAsync,
                      emptyTitle: '目前還沒有已加入的球局',
                      emptySubtitle: '你已核准或即將參加的球局會顯示在這裡。',
                      emptyBody: '前往「發現球局」即可加入。',
                      refresh: () async {
                        ref.invalidate(joinedGamesProvider);
                        await ref.read(joinedGamesProvider.future);
                      },
                      gameTileSubtitle: '已加入',
                    ),
                    _GamesTab(
                      gamesAsync: createdAsync,
                      emptyTitle: '目前還沒有我建立的球局',
                      emptySubtitle: '你主揪的球局發佈後會顯示在這裡。',
                      emptyBody: '建立一場球局後就會出現在這裡。',
                      refresh: () async {
                        ref.invalidate(createdGamesProvider);
                        await ref.read(createdGamesProvider.future);
                      },
                      gameTileSubtitle: '我建立的',
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
    required this.joinedActiveCount,
    required this.createdActiveCount,
    required this.joinedHistoryCount,
    required this.createdHistoryCount,
  });

  final int? joinedCount;
  final int? createdCount;
  final int? joinedActiveCount;
  final int? createdActiveCount;
  final int? joinedHistoryCount;
  final int? createdHistoryCount;

  @override
  Widget build(BuildContext context) {
    final String joinedLabel = joinedCount == null ? '...' : '$joinedCount';
    final String createdLabel = createdCount == null ? '...' : '$createdCount';
    final int? activeTotal =
        joinedActiveCount == null || createdActiveCount == null
            ? null
            : joinedActiveCount! + createdActiveCount!;
    final int? historyTotal =
        joinedHistoryCount == null || createdHistoryCount == null
            ? null
            : joinedHistoryCount! + createdHistoryCount!;
    final String activeLabel = activeTotal == null ? '...' : '$activeTotal';
    final String historyLabel = historyTotal == null ? '...' : '$historyTotal';

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
                    label: '即時資料',
                    icon: Icons.cloud_done_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '你的球局一目了然',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '不用翻好幾個頁面，就能追蹤已加入與主揪中的球局。',
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
                    label: '已加入 $joinedLabel 場',
                    icon: Icons.playlist_add_check_rounded,
                  ),
                  _HeroChip(
                    label: '主揪 $createdLabel 場',
                    icon: Icons.meeting_room_rounded,
                  ),
                  _HeroChip(
                    label: '可操作 $activeLabel 場',
                    icon: Icons.touch_app_rounded,
                  ),
                  _HeroChip(
                    label: '歷史 $historyLabel 場',
                    icon: Icons.history_rounded,
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
          final List<GameSummary> sortedGames = [...games]
            ..sort(_compareGameSummaryByStartAt);
          final List<GameSummary> currentGames = sortedGames
              .where((GameSummary game) => !game.isHistorical)
              .toList(growable: false);
          final List<GameSummary> historicalGames = sortedGames
              .where((GameSummary game) => game.isHistorical)
              .toList(growable: false);
          final bool isJoinedTab = gameTileSubtitle == '已加入';

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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                SectionCard(
                  title: isJoinedTab ? '已加入清單' : '主揪工作台',
                  subtitle: isJoinedTab
                      ? '已核准、待出席、已撤回與已進入歷史的球局都會保留。'
                      : '仍可管理的球局會先出現，歷史球局會另外分區。',
                  child: StatusCallout(
                    title: isJoinedTab ? '這裡是你的行程清單' : '這裡是你的主揪工作台',
                    message: isJoinedTab
                        ? '先看仍在進行中的球局，再從卡片上的狀態快速分辨可操作、已關閉與可回看的項目。'
                        : '先看仍可管理的球局，再從卡片上的狀態快速分辨可操作、已關閉與歷史紀錄。',
                    icon: isJoinedTab
                        ? Icons.event_available_rounded
                        : Icons.manage_accounts_rounded,
                    tone: isJoinedTab
                        ? StatusCalloutTone.neutral
                        : StatusCalloutTone.info,
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: isJoinedTab ? '目前行程' : '可管理球局',
                  subtitle: isJoinedTab ? '仍未進入歷史的球局會先放在這裡。' : '仍可管理的球局會先放在這裡。',
                  child: currentGames.isEmpty
                      ? StatusCallout(
                          title: isJoinedTab ? '目前沒有可操作的行程' : '目前沒有可管理的球局',
                          message: isJoinedTab
                              ? '你的球局已全部進入歷史；往下還能回看已結束或已取消的紀錄。'
                              : '你的球局已全部進入歷史；往下還能查看已結束或已取消的管理紀錄。',
                          icon: Icons.history_rounded,
                          tone: StatusCalloutTone.neutral,
                        )
                      : Column(
                          children: currentGames
                              .map(
                                (GameSummary game) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => context.pushNamed(
                                      AppRouteNames.gameDetail,
                                      pathParameters: <String, String>{
                                        'gameId': game.id,
                                      },
                                    ),
                                    child: _GameTile(
                                      game: game,
                                      subtitle: gameTileSubtitle,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
                if (historicalGames.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: isJoinedTab ? '歷史行程' : '主揪歷史紀錄',
                    subtitle: isJoinedTab
                        ? '已取消或已結束的球局會保留在這裡，方便回看。'
                        : '已取消或已結束的球局會保留在這裡，方便回看與整理。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        StatusCallout(
                          title: isJoinedTab ? '歷史紀錄' : '歷史主揪紀錄',
                          message: isJoinedTab
                              ? '這些球局已經不能再操作，但會保留在清單裡。'
                              : '這些球局已進入歷史，但仍可點進去查看內容與結果。',
                          icon: Icons.history_rounded,
                          tone: StatusCalloutTone.neutral,
                        ),
                        const SizedBox(height: 16),
                        ...historicalGames.map(
                          (GameSummary game) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.pushNamed(
                                AppRouteNames.gameDetail,
                                pathParameters: <String, String>{
                                  'gameId': game.id,
                                },
                              ),
                              child: _GameTile(
                                game: game,
                                subtitle: gameTileSubtitle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _PriceBadge(fee: game.fee),
              const SizedBox(width: 10),
              _MetaPill(
                icon: game.isHistorical
                    ? Icons.history_rounded
                    : game.isClosedForJoin
                        ? Icons.lock_rounded
                        : Icons.touch_app_rounded,
                label: game.isHistorical
                    ? '歷史紀錄'
                    : game.isClosedForJoin
                        ? '已關閉'
                        : '可操作',
              ),
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
                label: '${game.availableSpots}/${game.capacity} 個名額',
              ),
              _MetaPill(
                icon: Icons.flag_rounded,
                label: switch (game.status) {
                  'OPEN' => '開放中',
                  'FULL' => '已額滿',
                  'CANCELLED' => '已取消',
                  'COMPLETED' => '已結束',
                  _ => game.status,
                },
              ),
              _MetaPill(
                icon: subtitle == '我建立的'
                    ? Icons.rule_folder_rounded
                    : Icons.playlist_add_check_rounded,
                label: subtitle == '我建立的' ? '主揪工具' : '球友視角',
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
          const SizedBox(height: 12),
          if (subtitle == '我建立的') ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: ValueKey<String>(
                  game.isHistorical
                      ? 'view-history-${game.id}'
                      : 'manage-requests-${game.id}',
                ),
                onPressed: () => context.pushNamed(
                  game.isHistorical
                      ? AppRouteNames.gameDetail
                      : AppRouteNames.gameRequests,
                  pathParameters: <String, String>{
                    'gameId': game.id,
                  },
                ),
                icon: Icon(
                  game.isHistorical
                      ? Icons.history_rounded
                      : Icons.rule_folder_outlined,
                ),
                label: Text(game.isHistorical ? '查看歷史' : '管理申請'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _StatusNote(game: game, subtitle: subtitle),
        ],
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({
    required this.game,
    required this.subtitle,
  });

  final GameSummary game;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final String line = game.isHistorical
        ? '這場球局已進入歷史，只保留回看。'
        : game.isClosedForJoin
            ? '這場球局目前已關閉報名，仍可查看細節。'
            : subtitle == '我建立的'
                ? '先處理待審核申請，再看參加名單；已接受球友才會進入可聯絡範圍。'
                : '這場球局目前仍可加入或申請加入；已接受後才能查看聯絡方式。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: game.isHistorical
            ? const Color(0xFFF6F1E8)
            : game.isClosedForJoin
                ? const Color(0xFFF4F7EF)
                : const Color(0xFFEAF1E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: game.isHistorical
              ? const Color(0xFFE0D7C8)
              : game.isClosedForJoin
                  ? const Color(0xFFDDE5D8)
                  : const Color(0xFFCDE0CA),
        ),
      ),
      child: Text(
        line,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF55655B),
              height: 1.45,
            ),
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

int _activeGameCount(List<GameSummary>? games) {
  if (games == null) {
    return 0;
  }

  return games.where((GameSummary game) => !game.isHistorical).length;
}

int _historyGameCount(List<GameSummary>? games) {
  if (games == null) {
    return 0;
  }

  return games.where((GameSummary game) => game.isHistorical).length;
}

int _compareGameSummaryByStartAt(GameSummary a, GameSummary b) {
  return a.startAt.compareTo(b.startAt);
}
