import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/section_card.dart';
import '../../games/application/games_providers.dart';
import '../../games/data/games_repository.dart';

class GameDiscoveryPage extends ConsumerStatefulWidget {
  const GameDiscoveryPage({super.key});

  @override
  ConsumerState<GameDiscoveryPage> createState() => _GameDiscoveryPageState();
}

class _GameDiscoveryPageState extends ConsumerState<GameDiscoveryPage> {
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _feeMinController;
  late final TextEditingController _feeMaxController;

  @override
  void initState() {
    super.initState();
    final GamesFeedQuery query = ref.read(gamesFeedQueryProvider);
    _cityController = TextEditingController(text: query.city);
    _districtController = TextEditingController(text: query.district);
    _feeMinController = TextEditingController(
      text: query.feeMin?.toString() ?? '',
    );
    _feeMaxController = TextEditingController(
      text: query.feeMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _feeMinController.dispose();
    _feeMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GamesFeedQuery query = ref.watch(gamesFeedQueryProvider);
    final AsyncValue<PaginatedGames<GameSummary>> gamesAsync =
        ref.watch(gamesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
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
        child: AsyncStateView(
          isLoading: gamesAsync.isLoading,
          errorMessage:
              gamesAsync.hasError ? gamesAsync.error.toString() : null,
          child: gamesAsync.maybeWhen(
            data: (PaginatedGames<GameSummary> result) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(gamesListProvider);
                  await ref.read(gamesListProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _DiscoveryHero(
                        games: result.items,
                        totalCount: result.total,
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Search & filters',
                        subtitle:
                            'Narrow the feed by place, schedule, level, fee, and vacancy.',
                        child: _FilterPanel(
                          query: query,
                          cityController: _cityController,
                          districtController: _districtController,
                          feeMinController: _feeMinController,
                          feeMaxController: _feeMaxController,
                          onCityChanged: (String value) => _updateQuery(
                            (GamesFeedQuery current) =>
                                current.copyWith(city: value),
                          ),
                          onDistrictChanged: (String value) => _updateQuery(
                            (GamesFeedQuery current) =>
                                current.copyWith(district: value),
                          ),
                          onDatePressed: _pickDate,
                          onTimePresetChanged: (GamesFeedTimePreset preset) =>
                              _updateQuery(
                            (GamesFeedQuery current) =>
                                current.copyWith(timePreset: preset),
                          ),
                          onSkillLevelChanged: (String value) => _updateQuery(
                            (GamesFeedQuery current) =>
                                current.copyWith(skillLevel: value),
                          ),
                          onFeeMinChanged: (String value) => _updateFeeFilter(
                            isMin: true,
                            value: value,
                          ),
                          onFeeMaxChanged: (String value) => _updateFeeFilter(
                            isMin: false,
                            value: value,
                          ),
                          onVacancyOnlyChanged: (bool value) => _updateQuery(
                            (GamesFeedQuery current) =>
                                current.copyWith(vacancyOnly: value),
                          ),
                          onClearPressed: _clearFilters,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (query.hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SectionCard(
                            title: 'Active filters',
                            subtitle:
                                'Tap clear if you want to compare the full feed again.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _activeFilterChips(query),
                            ),
                          ),
                        ),
                      SectionCard(
                        title: 'Open matches',
                        subtitle:
                            '${result.items.length} visible · ${result.total} total',
                        child: Text(
                          result.items.isEmpty
                              ? 'No matches found with the current filter set.'
                              : 'Sorted by date, then start time, so the earliest viable games appear first.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (result.items.isEmpty)
                        const SectionCard(
                          title: 'Nothing live right now',
                          subtitle:
                              'No open matches were found in the current feed.',
                          child:
                              Text('Try adjusting filters or create a game.'),
                        )
                      else
                        ...result.items.map(
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
                              child: _GamePreviewCard(game: game),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  void _updateQuery(
    GamesFeedQuery Function(GamesFeedQuery current) update,
  ) {
    final GamesFeedQuery current = ref.read(gamesFeedQueryProvider);
    ref.read(gamesFeedQueryProvider.notifier).state = update(current);
  }

  void _updateFeeFilter({
    required bool isMin,
    required String value,
  }) {
    final int? parsed = int.tryParse(value.trim());
    _updateQuery(
      (GamesFeedQuery current) => current.copyWith(
        feeMin: isMin ? parsed : current.feeMin,
        feeMax: isMin ? current.feeMax : parsed,
      ),
    );
  }

  Future<void> _pickDate() async {
    final GamesFeedQuery current = ref.read(gamesFeedQueryProvider);
    final DateTime now = DateTime.now();
    final DateTime initialDate = current.date ?? now;
    final DateTime firstDate = DateTime(now.year - 1, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 1, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    _updateQuery(
      (GamesFeedQuery currentQuery) => currentQuery.copyWith(date: picked),
    );
  }

  void _clearFilters() {
    _cityController.clear();
    _districtController.clear();
    _feeMinController.clear();
    _feeMaxController.clear();
    ref.read(gamesFeedQueryProvider.notifier).state = const GamesFeedQuery();
  }

  List<Widget> _activeFilterChips(GamesFeedQuery query) {
    final List<Widget> chips = <Widget>[];

    if (query.city.trim().isNotEmpty) {
      chips.add(_FilterChip(label: 'City: ${query.city.trim()}'));
    }

    if (query.district.trim().isNotEmpty) {
      chips.add(_FilterChip(label: 'District: ${query.district.trim()}'));
    }

    if (query.date != null) {
      chips.add(
        _FilterChip(label: 'Date: ${_formatDate(query.date!)}'),
      );
    }

    if (query.timePreset != GamesFeedTimePreset.any) {
      chips.add(
        _FilterChip(label: 'Time: ${_timePresetLabel(query.timePreset)}'),
      );
    }

    if (query.skillLevel.trim().isNotEmpty) {
      chips.add(_FilterChip(label: 'Skill: ${query.skillLevel.trim()}'));
    }

    if (query.feeMin != null || query.feeMax != null) {
      chips.add(
        _FilterChip(
          label: 'Fee: ${_formatFeeRange(query.feeMin, query.feeMax)}',
        ),
      );
    }

    if (query.vacancyOnly) {
      chips.add(const _FilterChip(label: 'Vacancy only'));
    }

    return chips;
  }
}

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({
    required this.games,
    required this.totalCount,
  });

  final List<GameSummary> games;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final int openSpots = games.fold<int>(
      0,
      (int total, GameSummary game) => total + game.availableSpots,
    );
    final int manualGames =
        games.where((GameSummary game) => game.approvalMode == 'MANUAL').length;
    final String nextGameLabel = games.isEmpty
        ? 'No live games yet'
        : '${_formatDate(games.first.startAt)} · ${_formatTime(games.first.startAt)}';

    return Container(
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
                    Icons.sports_tennis_rounded,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _HeroBadge(
                  label: '$totalCount live',
                  icon: Icons.wifi_tethering_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Find a game worth joining',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the live feed, compare the practical details, and jump into the best fit faster.',
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
                  label: '$totalCount games',
                  icon: Icons.event_available_rounded,
                ),
                _HeroChip(
                  label: '$openSpots open spots',
                  icon: Icons.airline_seat_recline_normal_rounded,
                ),
                _HeroChip(
                  label: '$manualGames manual',
                  icon: Icons.rule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Next in feed: $nextGameLabel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.query,
    required this.cityController,
    required this.districtController,
    required this.feeMinController,
    required this.feeMaxController,
    required this.onCityChanged,
    required this.onDistrictChanged,
    required this.onDatePressed,
    required this.onTimePresetChanged,
    required this.onSkillLevelChanged,
    required this.onFeeMinChanged,
    required this.onFeeMaxChanged,
    required this.onVacancyOnlyChanged,
    required this.onClearPressed,
  });

  final GamesFeedQuery query;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController feeMinController;
  final TextEditingController feeMaxController;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onDistrictChanged;
  final VoidCallback onDatePressed;
  final ValueChanged<GamesFeedTimePreset> onTimePresetChanged;
  final ValueChanged<String> onSkillLevelChanged;
  final ValueChanged<String> onFeeMinChanged;
  final ValueChanged<String> onFeeMaxChanged;
  final ValueChanged<bool> onVacancyOnlyChanged;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('games-filter-city'),
                controller: cityController,
                decoration: _filterDecoration(
                  label: 'City',
                  hint: 'Taipei City',
                  icon: Icons.location_city_rounded,
                ),
                textInputAction: TextInputAction.next,
                onChanged: onCityChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('games-filter-district'),
                controller: districtController,
                decoration: _filterDecoration(
                  label: 'District',
                  hint: "Da'an",
                  icon: Icons.map_rounded,
                ),
                textInputAction: TextInputAction.next,
                onChanged: onDistrictChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                key: const Key('games-filter-date'),
                onPressed: onDatePressed,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  query.date == null
                      ? 'Pick date'
                      : 'Date: ${_formatDate(query.date!)}',
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: const Key('games-filter-skill'),
                isExpanded: true,
                initialValue:
                    query.skillLevel.trim().isEmpty ? '' : query.skillLevel,
                decoration: _filterDecoration(
                  label: 'Skill',
                  icon: Icons.emoji_events_rounded,
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: '', child: Text('Any level')),
                  DropdownMenuItem<String>(value: 'L1', child: Text('L1')),
                  DropdownMenuItem<String>(value: 'L2', child: Text('L2')),
                  DropdownMenuItem<String>(value: 'L3', child: Text('L3')),
                  DropdownMenuItem<String>(value: 'L4', child: Text('L4')),
                  DropdownMenuItem<String>(value: 'L5', child: Text('L5')),
                ],
                onChanged: (String? value) => onSkillLevelChanged(value ?? ''),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('games-filter-fee-min'),
                controller: feeMinController,
                keyboardType: TextInputType.number,
                decoration: _filterDecoration(
                  label: 'Fee min',
                  hint: '0',
                  icon: Icons.payments_rounded,
                ),
                onChanged: onFeeMinChanged,
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('games-filter-fee-max'),
                controller: feeMaxController,
                keyboardType: TextInputType.number,
                decoration: _filterDecoration(
                  label: 'Fee max',
                  hint: '999',
                  icon: Icons.payments_rounded,
                ),
                onChanged: onFeeMaxChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a date first, then refine the time window.',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF66776D),
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GamesFeedTimePreset.values
              .map(
                (GamesFeedTimePreset preset) => ChoiceChip(
                  key: Key('games-filter-time-${preset.name}'),
                  label: Text(_timePresetLabel(preset)),
                  selected: query.timePreset == preset,
                  onSelected:
                      query.date == null && preset != GamesFeedTimePreset.any
                          ? null
                          : (_) => onTimePresetChanged(preset),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            FilterChip(
              key: const Key('games-filter-vacancy'),
              label: const Text('Vacancy only'),
              selected: query.vacancyOnly,
              onSelected: onVacancyOnlyChanged,
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('games-filter-clear'),
              onPressed: onClearPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ],
    );
  }
}

class _GamePreviewCard extends StatelessWidget {
  const _GamePreviewCard({
    required this.game,
  });

  final GameSummary game;

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
          const SizedBox(height: 8),
          Text(
            'Host ${game.host.nickname} · ${_formatDuration(game.startAt, game.endAt)} · ${_formatDate(game.startAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A7A70),
              fontWeight: FontWeight.w700,
            ),
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
                icon: Icons.timer_rounded,
                label: _formatDuration(game.startAt, game.endAt),
              ),
              _MetaPill(
                icon: Icons.emoji_events_rounded,
                label: _skillRangeLabel(game.skillLevelMin, game.skillLevelMax),
              ),
              _MetaPill(
                icon: Icons.view_module_rounded,
                label: '${game.courtCount} courts',
              ),
              _MetaPill(
                icon: Icons.sports_tennis_rounded,
                label: _shuttleLabel(game.shuttleType),
              ),
              _MetaPill(
                icon: Icons.people_alt_rounded,
                label: '${game.availableSpots} spots left',
              ),
              _MetaPill(
                icon: Icons.flag_rounded,
                label: game.approvalMode == 'MANUAL'
                    ? 'Manual approval'
                    : 'Auto approval',
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF4F7EF),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF35513C),
            fontWeight: FontWeight.w700,
          ),
      side: const BorderSide(color: Color(0xFFD2E0CF)),
    );
  }
}

InputDecoration _filterDecoration({
  required String label,
  IconData? icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD9E4D6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD9E4D6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF1E6B42), width: 1.4),
    ),
    isDense: true,
  );
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDuration(DateTime startAt, DateTime endAt) {
  final Duration duration = endAt.difference(startAt);
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  }

  if (hours > 0) {
    return '${hours}h';
  }

  return '${duration.inMinutes}m';
}

String _skillRangeLabel(String minLevel, String? maxLevel) {
  if (maxLevel == null || maxLevel == minLevel) {
    return minLevel;
  }

  return '$minLevel-$maxLevel';
}

String _shuttleLabel(String? shuttleType) {
  switch (shuttleType) {
    case 'FEATHER':
      return 'Feather';
    case 'NYLON':
      return 'Nylon';
    case 'MIXED':
      return 'Mixed shuttle';
    case null:
      return 'Shuttle TBD';
  }

  return 'Shuttle TBD';
}

String _formatFeeRange(int? minFee, int? maxFee) {
  if (minFee != null && maxFee != null) {
    return 'NT\$$minFee - NT\$$maxFee';
  }

  if (minFee != null) {
    return 'NT\$$minFee+';
  }

  if (maxFee != null) {
    return 'Up to NT\$$maxFee';
  }

  return 'Any fee';
}

String _timePresetLabel(GamesFeedTimePreset preset) {
  switch (preset) {
    case GamesFeedTimePreset.any:
      return 'Any time';
    case GamesFeedTimePreset.morning:
      return 'Morning';
    case GamesFeedTimePreset.afternoon:
      return 'Afternoon';
    case GamesFeedTimePreset.evening:
      return 'Evening';
    case GamesFeedTimePreset.late:
      return 'Late night';
  }
}
