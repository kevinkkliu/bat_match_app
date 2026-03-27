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
      appBar: AppBar(title: const Text('發現球局')),
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
                        title: '搜尋與篩選',
                        subtitle: '用地點、時間、程度、費用與是否有空位來縮小名單。',
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
                            title: '目前篩選',
                            subtitle: '想回到完整名單時，可以直接清除篩選。',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _activeFilterChips(query),
                            ),
                          ),
                        ),
                      SectionCard(
                        title: '開放中的球局',
                        subtitle:
                            '顯示 ${result.items.length} 場 · 共 ${result.total} 場',
                        child: Text(
                          result.items.isEmpty
                              ? '目前篩選條件下找不到符合的球局。'
                              : '依日期與開打時間排序，較早可加入的球局會優先顯示。',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (result.items.isEmpty)
                        const SectionCard(
                          title: '目前沒有即時開放的球局',
                          subtitle: '目前名單裡沒有開放中的球局。',
                          child: Text('可以調整篩選條件，或直接建立一場球局。'),
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
      chips.add(_FilterChip(label: '城市：${query.city.trim()}'));
    }

    if (query.district.trim().isNotEmpty) {
      chips.add(_FilterChip(label: '行政區：${query.district.trim()}'));
    }

    if (query.date != null) {
      chips.add(
        _FilterChip(label: '日期：${_formatDate(query.date!)}'),
      );
    }

    if (query.timePreset != GamesFeedTimePreset.any) {
      chips.add(
        _FilterChip(label: '時段：${_timePresetLabel(query.timePreset)}'),
      );
    }

    if (query.skillLevel.trim().isNotEmpty) {
      chips.add(
        _FilterChip(label: '程度：${_skillLevelDisplayLabel(query.skillLevel)}'),
      );
    }

    if (query.feeMin != null || query.feeMax != null) {
      chips.add(
        _FilterChip(
          label: '費用：${_formatFeeRange(query.feeMin, query.feeMax)}',
        ),
      );
    }

    if (query.vacancyOnly) {
      chips.add(const _FilterChip(label: '只看有空位'));
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
        ? '目前還沒有即時球局'
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
                  label: '即時 $totalCount 場',
                  icon: Icons.wifi_tethering_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '找到值得加入的球局',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '先看即時名單、比對關鍵資訊，再更快找到合適的場。',
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
                  label: '球局 $totalCount 場',
                  icon: Icons.event_available_rounded,
                ),
                _HeroChip(
                  label: '剩餘 $openSpots 個名額',
                  icon: Icons.airline_seat_recline_normal_rounded,
                ),
                _HeroChip(
                  label: '人工審核 $manualGames 場',
                  icon: Icons.rule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '下一場：$nextGameLabel',
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
                  label: '城市',
                  hint: '台北市',
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
                  label: '行政區',
                  hint: '大安區',
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
                      ? '選擇日期'
                      : '日期：${_formatDate(query.date!)}',
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
                  label: '程度',
                  icon: Icons.emoji_events_rounded,
                  helperText: '選擇最符合這場球局的節奏。',
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: '', child: Text('不限程度')),
                  DropdownMenuItem<String>(
                    value: 'L1',
                    child: Text('L1 初學入門'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'L2',
                    child: Text('L2 穩定練習中'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'L3',
                    child: Text('L3 穩定球友'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'L4',
                    child: Text('L4 高階球友'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'L5',
                    child: Text('L5 競賽程度'),
                  ),
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
                  label: '費用下限',
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
                  label: '費用上限',
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
          '先選日期，再細調時段。',
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
              label: const Text('只看有空位'),
              selected: query.vacancyOnly,
              onSelected: onVacancyOnlyChanged,
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('games-filter-clear'),
              onPressed: onClearPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('清除篩選'),
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
            '主揪 ${game.host.nickname} · ${_formatDuration(game.startAt, game.endAt)} · ${_formatDate(game.startAt)}',
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
                label: _skillLevelRangeLabel(
                  game.skillLevelMin,
                  game.skillLevelMax,
                ),
              ),
              _MetaPill(
                icon: Icons.view_module_rounded,
                label: '${game.courtCount} 面場地',
              ),
              _MetaPill(
                icon: Icons.sports_tennis_rounded,
                label: _shuttleLabel(game.shuttleType),
              ),
              _MetaPill(
                icon: Icons.people_alt_rounded,
                label: '${game.availableSpots} 個名額',
              ),
              _MetaPill(
                icon: Icons.flag_rounded,
                label: game.approvalMode == 'MANUAL' ? '人工審核' : '自動審核',
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
  String? helperText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helperText,
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

String _shuttleLabel(String? shuttleType) {
  switch (shuttleType) {
    case 'FEATHER':
      return '羽毛球';
    case 'NYLON':
      return '尼龍球';
    case 'MIXED':
      return '混合球種';
    case null:
      return '球種待定';
  }

  return '球種待定';
}

String _formatFeeRange(int? minFee, int? maxFee) {
  if (minFee != null && maxFee != null) {
    return 'NT\$$minFee - NT\$$maxFee';
  }

  if (minFee != null) {
    return 'NT\$$minFee+';
  }

  if (maxFee != null) {
    return '最高 NT\$$maxFee';
  }

  return '不限費用';
}

String _timePresetLabel(GamesFeedTimePreset preset) {
  switch (preset) {
    case GamesFeedTimePreset.any:
      return '不限時段';
    case GamesFeedTimePreset.morning:
      return '早上';
    case GamesFeedTimePreset.afternoon:
      return '下午';
    case GamesFeedTimePreset.evening:
      return '晚上';
    case GamesFeedTimePreset.late:
      return '深夜';
  }
}

String _skillLevelDisplayLabel(String skillLevel) {
  final String normalized = skillLevel.trim().toUpperCase();
  if (normalized.isEmpty) {
    return '不限程度';
  }

  switch (normalized) {
    case 'L1':
      return 'L1 初學入門';
    case 'L2':
      return 'L2 穩定練習中';
    case 'L3':
      return 'L3 穩定球友';
    case 'L4':
      return 'L4 高階球友';
    case 'L5':
      return 'L5 競賽程度';
    default:
      return skillLevel;
  }
}

String _skillLevelRangeLabel(String minLevel, String? maxLevel) {
  if (maxLevel == null || maxLevel.trim().isEmpty) {
    return _skillLevelDisplayLabel(minLevel);
  }

  return '${_skillLevelDisplayLabel(minLevel)} - ${_skillLevelDisplayLabel(maxLevel)}';
}
