import 'package:bat_dating_app_mobile/app/app.dart';
import 'package:bat_dating_app_mobile/app/router.dart';
import 'package:bat_dating_app_mobile/features/create_game/presentation/create_game_page.dart';
import 'package:bat_dating_app_mobile/features/games/application/games_providers.dart';
import 'package:bat_dating_app_mobile/features/games/data/games_repository.dart';
import 'package:bat_dating_app_mobile/features/profile/application/profile_providers.dart';
import 'package:bat_dating_app_mobile/features/profile/data/profile_repository.dart';
import 'package:bat_dating_app_mobile/features/profile/presentation/profile_page.dart';
import 'package:bat_dating_app_mobile/shared/models/game_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(Dio()) {
    _details['game-open-001'] = _buildOpenGame(
      id: 'game-open-001',
      title: 'Wednesday Doubles',
      hostNickname: 'Kevin',
    );
    _details['game-open-002'] = _buildOpenGame(
      id: 'game-open-002',
      title: 'Banqiao Rally',
      hostNickname: 'Mina',
      city: 'New Taipei City',
      district: 'Banqiao',
      fee: 320,
      availableSpots: 1,
      skillLevelMin: 'L3',
      skillLevelMax: 'L5',
      shuttleType: 'NYLON',
      approvalMode: 'MANUAL',
      gameDate: DateTime.parse('2026-03-30'),
      startAt: DateTime.parse('2026-03-30T20:00:00+08:00'),
      endAt: DateTime.parse('2026-03-30T22:00:00+08:00'),
      notes: 'Intermediate-friendly rally night.',
    );
    _details['game-open-003'] = _buildOpenGame(
      id: 'game-open-003',
      title: 'Friday Packed Session',
      hostNickname: 'Chen',
      city: 'Taipei City',
      district: 'Xinyi',
      fee: 260,
      availableSpots: 0,
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      shuttleType: 'FEATHER',
      approvalMode: 'AUTO',
      gameDate: DateTime.parse('2026-03-31'),
      startAt: DateTime.parse('2026-03-31T19:30:00+08:00'),
      endAt: DateTime.parse('2026-03-31T21:30:00+08:00'),
      notes: 'Fully booked but left open in the feed for comparison.',
    );
    _details['game-joined-001'] = _buildJoinedGame(
      id: 'game-joined-001',
      title: 'Sunday Rally',
      hostNickname: 'Mia',
    );
    _details['game-created-001'] = _buildCreatedGame(
      id: 'game-created-001',
      title: 'Friday Night Ladder',
      hostNickname: 'Kevin',
    );
    _details['game-cancelled-001'] = _buildCancelledGame(
      id: 'game-cancelled-001',
      title: 'Saturday Cancelled Session',
      hostNickname: 'Kevin',
    );
    _details['game-withdrawn-001'] = _buildWithdrawnGame(
      id: 'game-withdrawn-001',
      title: 'Thursday Withdrawn Session',
      hostNickname: 'Mina',
    );
    _details['game-completed-001'] = _buildCompletedGame(
      id: 'game-completed-001',
      title: 'Sunday Completed Session',
      hostNickname: 'Kevin',
    );

    _joinedGames.add(_details['game-joined-001']!);
    _createdGames.add(_details['game-created-001']!);
    _createdGames.add(_details['game-cancelled-001']!);
    _createdGames.add(_details['game-completed-001']!);

    _joinRequestsByGame['game-created-001'] = <JoinRequestSummary>[
      _approvedRequest(
        id: 'request-000',
        gameId: 'game-created-001',
        userId: 'user-000',
        message: 'Already confirmed.',
        applicant: _applicant(
          id: 'user-000',
          nickname: 'Carol',
          skillLevel: 'L3',
          preferredCity: 'Taipei City',
          preferredDistrict: 'Songshan',
        ),
      ),
      _pendingRequest(
        id: 'request-001',
        gameId: 'game-created-001',
        userId: 'user-001',
        message: 'I can bring shuttles.',
        applicant: _applicant(
          id: 'user-001',
          nickname: 'Ava',
          skillLevel: 'L3',
          preferredCity: 'Taipei City',
          preferredDistrict: "Da'an",
        ),
      ),
      _pendingRequest(
        id: 'request-002',
        gameId: 'game-created-001',
        userId: 'user-002',
        message: 'Happy to join.',
        applicant: _applicant(
          id: 'user-002',
          nickname: 'Ben',
          skillLevel: 'L4',
          preferredCity: 'New Taipei City',
          preferredDistrict: 'Banqiao',
        ),
      ),
    ];
  }

  final Map<String, GameDetail> _details = <String, GameDetail>{};
  final List<GameSummary> _joinedGames = <GameSummary>[];
  final List<GameSummary> _createdGames = <GameSummary>[];
  final Map<String, List<JoinRequestSummary>> _joinRequestsByGame =
      <String, List<JoinRequestSummary>>{};

  @override
  Future<PaginatedGames<GameSummary>> fetchGames({
    GamesFeedQuery query = const GamesFeedQuery(),
  }) async {
    final List<GameSummary> matched = _details.values.where((GameSummary game) {
      return _matchesQuery(game, query);
    }).toList()
      ..sort((GameSummary a, GameSummary b) {
        final int dateCompare = a.gameDate.compareTo(b.gameDate);
        if (dateCompare != 0) {
          return dateCompare;
        }

        final int timeCompare = a.startAt.compareTo(b.startAt);
        if (timeCompare != 0) {
          return timeCompare;
        }

        return a.title.compareTo(b.title);
      });

    return PaginatedGames<GameSummary>(
      items: matched,
      page: query.page,
      pageSize: query.pageSize,
      total: matched.length,
    );
  }

  @override
  Future<GameDetail> fetchGameDetail(String gameId) async {
    return _details[gameId]!;
  }

  @override
  Future<GameJoinResult> joinGame(
    String gameId, {
    String? message,
  }) async {
    final GameDetail current = _details[gameId]!;
    final GameDetail joined = GameDetail(
      id: current.id,
      title: current.title,
      city: current.city,
      district: current.district,
      venueName: current.venueName,
      venueAddress: current.venueAddress,
      gameDate: current.gameDate,
      startAt: current.startAt,
      endAt: current.endAt,
      skillLevelMin: current.skillLevelMin,
      skillLevelMax: current.skillLevelMax,
      fee: current.fee,
      capacity: current.capacity,
      availableSpots: current.availableSpots - 1,
      courtCount: current.courtCount,
      shuttleType: current.shuttleType,
      approvalMode: current.approvalMode,
      status: current.status,
      host: current.host,
      notes: current.notes,
      joinSummary: GameJoinSummary(
        currentUserStatus: 'APPROVED',
        pendingCount: current.joinSummary.pendingCount,
        approvedCount: current.joinSummary.approvedCount + 1,
      ),
    );

    _details[gameId] = joined;
    _joinedGames.removeWhere((GameSummary item) => item.id == gameId);
    _joinedGames.insert(0, joined);

    return GameJoinResult(
      joinRequest: JoinRequestSummary(
        id: 'join-$gameId',
        gameId: gameId,
        userId: 'user-current',
        status: 'APPROVED',
        message: message,
        respondedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
        approvedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
        rejectedReason: null,
        createdAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
        updatedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
        applicant: _applicant(
          id: 'user-current',
          nickname: 'Current User',
          skillLevel: 'L3',
          preferredCity: 'Taipei City',
          preferredDistrict: "Da'an",
        ),
      ),
      game: GameMutationSummary(
        id: gameId,
        availableSpots: joined.availableSpots,
        status: joined.status,
      ),
    );
  }

  @override
  Future<List<GameSummary>> fetchJoinedGames() async {
    return List<GameSummary>.unmodifiable(_joinedGames);
  }

  @override
  Future<List<GameSummary>> fetchCreatedGames() async {
    return List<GameSummary>.unmodifiable(_createdGames);
  }

  @override
  Future<List<JoinRequestSummary>> fetchGameJoinRequests(String gameId) async {
    return List<JoinRequestSummary>.unmodifiable(
      _joinRequestsByGame[gameId] ?? <JoinRequestSummary>[],
    );
  }

  @override
  Future<JoinRequestSummary> approveJoinRequest(String joinRequestId) async {
    final _JoinRequestLookup lookup = _findJoinRequest(joinRequestId);
    final JoinRequestSummary approved = _copyJoinRequest(
      lookup.request,
      status: 'APPROVED',
      respondedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
      approvedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
      rejectedReason: null,
    );

    _replaceJoinRequest(lookup.gameId, approved);
    _adjustCreatedGameAfterModeration(lookup.gameId);
    return approved;
  }

  @override
  Future<JoinRequestSummary> rejectJoinRequest(
    String joinRequestId, {
    String? reason,
  }) async {
    final _JoinRequestLookup lookup = _findJoinRequest(joinRequestId);
    final JoinRequestSummary rejected = _copyJoinRequest(
      lookup.request,
      status: 'REJECTED',
      respondedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
      approvedAt: null,
      rejectedReason: reason ?? 'Not a fit',
    );

    _replaceJoinRequest(lookup.gameId, rejected);
    return rejected;
  }

  GameDetail _buildOpenGame({
    required String id,
    required String title,
    required String hostNickname,
    String city = 'Taipei City',
    String district = "Da'an",
    int fee = 200,
    int availableSpots = 3,
    String skillLevelMin = 'L2',
    String? skillLevelMax = 'L4',
    String? shuttleType = 'FEATHER',
    String approvalMode = 'AUTO',
    DateTime? gameDate,
    DateTime? startAt,
    DateTime? endAt,
    String? notes,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: city,
      district: district,
      venueName: 'NTU Sports Center',
      venueAddress: 'No. 1, Sec. 4, Roosevelt Rd.',
      gameDate: gameDate ?? DateTime.parse('2026-03-25'),
      startAt: startAt ?? DateTime.parse('2026-03-25T19:00:00+08:00'),
      endAt: endAt ?? DateTime.parse('2026-03-25T21:00:00+08:00'),
      skillLevelMin: skillLevelMin,
      skillLevelMax: skillLevelMax,
      fee: fee,
      capacity: 8,
      availableSpots: availableSpots,
      courtCount: 2,
      shuttleType: shuttleType,
      approvalMode: approvalMode,
      status: 'OPEN',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L3',
        preferredCity: city,
        preferredDistrict: district,
      ),
      notes: notes ?? 'Bring indoor shoes.',
      joinSummary: const GameJoinSummary(
        currentUserStatus: null,
        pendingCount: 0,
        approvedCount: 5,
      ),
    );
  }

  bool _matchesQuery(GameSummary game, GamesFeedQuery query) {
    if (game.status == 'CANCELLED' || game.status == 'COMPLETED') {
      return false;
    }

    if (query.city.trim().isNotEmpty &&
        !game.city.toLowerCase().contains(query.city.trim().toLowerCase())) {
      return false;
    }

    if (query.district.trim().isNotEmpty &&
        !game.district
            .toLowerCase()
            .contains(query.district.trim().toLowerCase())) {
      return false;
    }

    if (query.date != null) {
      if (!_isSameDate(game.gameDate, query.date!)) {
        return false;
      }
    }

    if (query.timePreset != GamesFeedTimePreset.any && query.date != null) {
      final _TimeWindow window = _timeWindowForPreset(query.timePreset);
      final DateTime from = DateTime(
        query.date!.year,
        query.date!.month,
        query.date!.day,
        window.startHour,
        window.startMinute,
      );
      final DateTime to = DateTime(
        query.date!.year,
        query.date!.month,
        query.date!.day,
        window.endHour,
        window.endMinute,
      );
      if (game.startAt.isBefore(from) || game.startAt.isAfter(to)) {
        return false;
      }
    }

    if (query.skillLevel.trim().isNotEmpty) {
      final int userLevelIndex = _skillLevelIndex(query.skillLevel.trim());
      final int minIndex = _skillLevelIndex(game.skillLevelMin);
      final int maxIndex = _skillLevelIndex(game.skillLevelMax ?? 'L5');
      if (userLevelIndex < minIndex || userLevelIndex > maxIndex) {
        return false;
      }
    }

    if (query.feeMin != null && game.fee < query.feeMin!) {
      return false;
    }

    if (query.feeMax != null && game.fee > query.feeMax!) {
      return false;
    }

    if (query.vacancyOnly && game.availableSpots <= 0) {
      return false;
    }

    return true;
  }

  GameDetail _buildJoinedGame({
    required String id,
    required String title,
    required String hostNickname,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: 'Taipei City',
      district: 'Xinyi',
      venueName: 'Tmall Sports Hall',
      venueAddress: 'No. 88, Songren Rd.',
      gameDate: DateTime.parse('2026-03-28'),
      startAt: DateTime.parse('2026-03-28T20:00:00+08:00'),
      endAt: DateTime.parse('2026-03-28T22:00:00+08:00'),
      skillLevelMin: 'L3',
      skillLevelMax: 'L5',
      fee: 250,
      capacity: 8,
      availableSpots: 2,
      courtCount: 2,
      shuttleType: 'MIXED',
      approvalMode: 'MANUAL',
      status: 'OPEN',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L4',
        preferredCity: 'Taipei City',
        preferredDistrict: 'Xinyi',
        phoneNumber: '0912-345-678',
        lineId: 'kevin.host',
      ),
      notes: 'Bring your own water bottle.',
      joinSummary: const GameJoinSummary(
        currentUserStatus: 'APPROVED',
        pendingCount: 0,
        approvedCount: 6,
      ),
    );
  }

  GameDetail _buildCreatedGame({
    required String id,
    required String title,
    required String hostNickname,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: 'New Taipei City',
      district: 'Banqiao',
      venueName: 'Banqiao Sports Center',
      venueAddress: 'No. 55, Civic Blvd.',
      gameDate: DateTime.parse('2026-03-29'),
      startAt: DateTime.parse('2026-03-29T18:30:00+08:00'),
      endAt: DateTime.parse('2026-03-29T20:30:00+08:00'),
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      fee: 180,
      capacity: 10,
      availableSpots: 4,
      courtCount: 2,
      shuttleType: 'FEATHER',
      approvalMode: 'AUTO',
      status: 'OPEN',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L4',
        preferredCity: 'New Taipei City',
        preferredDistrict: 'Banqiao',
      ),
      notes: null,
      joinSummary: const GameJoinSummary(
        currentUserStatus: null,
        pendingCount: 2,
        approvedCount: 3,
      ),
    );
  }

  GameDetail _buildCancelledGame({
    required String id,
    required String title,
    required String hostNickname,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: 'Taipei City',
      district: "Da'an",
      venueName: "Da'an Sports Center",
      venueAddress: 'No. 7, Xinsheng S. Rd.',
      gameDate: DateTime.parse('2026-04-01'),
      startAt: DateTime.parse('2026-04-01T19:00:00+08:00'),
      endAt: DateTime.parse('2026-04-01T21:00:00+08:00'),
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      fee: 220,
      capacity: 8,
      availableSpots: 0,
      courtCount: 2,
      shuttleType: 'FEATHER',
      approvalMode: 'MANUAL',
      status: 'CANCELLED',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L3',
        preferredCity: 'Taipei City',
        preferredDistrict: "Da'an",
      ),
      notes: 'This session has been cancelled.',
      joinSummary: const GameJoinSummary(
        currentUserStatus: null,
        pendingCount: 0,
        approvedCount: 0,
      ),
    );
  }

  GameDetail _buildWithdrawnGame({
    required String id,
    required String title,
    required String hostNickname,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: 'Taichung City',
      district: 'Xitun',
      venueName: 'Taichung Sports Center',
      venueAddress: 'No. 100, Taiwan Blvd.',
      gameDate: DateTime.parse('2026-04-02'),
      startAt: DateTime.parse('2026-04-02T18:30:00+08:00'),
      endAt: DateTime.parse('2026-04-02T20:30:00+08:00'),
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      fee: 240,
      capacity: 8,
      availableSpots: 2,
      courtCount: 2,
      shuttleType: 'MIXED',
      approvalMode: 'MANUAL',
      status: 'CANCELLED',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L4',
        preferredCity: 'Taichung City',
        preferredDistrict: 'Xitun',
      ),
      notes: 'Your previous request has been withdrawn.',
      joinSummary: const GameJoinSummary(
        currentUserStatus: 'WITHDRAWN',
        pendingCount: 0,
        approvedCount: 0,
      ),
    );
  }

  GameDetail _buildCompletedGame({
    required String id,
    required String title,
    required String hostNickname,
  }) {
    return GameDetail(
      id: id,
      title: title,
      city: 'Taipei City',
      district: 'Zhongzheng',
      venueName: 'Zhongzheng Sports Center',
      venueAddress: 'No. 21, Section 1, Roosevelt Rd.',
      gameDate: DateTime.parse('2026-04-03'),
      startAt: DateTime.parse('2026-04-03T19:30:00+08:00'),
      endAt: DateTime.parse('2026-04-03T21:30:00+08:00'),
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      fee: 230,
      capacity: 8,
      availableSpots: 0,
      courtCount: 2,
      shuttleType: 'FEATHER',
      approvalMode: 'MANUAL',
      status: 'COMPLETED',
      host: GameHostSummary(
        id: 'host-$id',
        nickname: hostNickname,
        avatarUrl: null,
        gender: null,
        skillLevel: 'L4',
        preferredCity: 'Taipei City',
        preferredDistrict: 'Zhongzheng',
      ),
      notes: 'This session has already been completed.',
      joinSummary: const GameJoinSummary(
        currentUserStatus: null,
        pendingCount: 0,
        approvedCount: 0,
      ),
    );
  }

  JoinRequestSummary _pendingRequest({
    required String id,
    required String gameId,
    required String userId,
    required String message,
    required JoinRequestApplicant applicant,
  }) {
    return JoinRequestSummary(
      id: id,
      gameId: gameId,
      userId: userId,
      status: 'PENDING',
      message: message,
      respondedAt: null,
      approvedAt: null,
      rejectedReason: null,
      createdAt: DateTime.parse('2026-03-21T11:00:00+08:00'),
      updatedAt: DateTime.parse('2026-03-21T11:00:00+08:00'),
      applicant: applicant,
    );
  }

  JoinRequestSummary _approvedRequest({
    required String id,
    required String gameId,
    required String userId,
    required String message,
    required JoinRequestApplicant applicant,
  }) {
    return JoinRequestSummary(
      id: id,
      gameId: gameId,
      userId: userId,
      status: 'APPROVED',
      message: message,
      respondedAt: DateTime.parse('2026-03-21T10:30:00+08:00'),
      approvedAt: DateTime.parse('2026-03-21T10:30:00+08:00'),
      rejectedReason: null,
      createdAt: DateTime.parse('2026-03-21T10:00:00+08:00'),
      updatedAt: DateTime.parse('2026-03-21T10:30:00+08:00'),
      applicant: applicant,
    );
  }

  JoinRequestApplicant _applicant({
    required String id,
    required String nickname,
    required String skillLevel,
    required String preferredCity,
    required String preferredDistrict,
  }) {
    return JoinRequestApplicant(
      id: id,
      nickname: nickname,
      avatarUrl: null,
      gender: null,
      skillLevel: skillLevel,
      preferredCity: preferredCity,
      preferredDistrict: preferredDistrict,
    );
  }

  _JoinRequestLookup _findJoinRequest(String joinRequestId) {
    for (final MapEntry<String, List<JoinRequestSummary>> entry
        in _joinRequestsByGame.entries) {
      for (final JoinRequestSummary request in entry.value) {
        if (request.id == joinRequestId) {
          return _JoinRequestLookup(gameId: entry.key, request: request);
        }
      }
    }

    throw StateError('Request not found: $joinRequestId');
  }

  void _replaceJoinRequest(String gameId, JoinRequestSummary updated) {
    final List<JoinRequestSummary> requests = List<JoinRequestSummary>.from(
        _joinRequestsByGame[gameId] ?? <JoinRequestSummary>[]);
    final int index =
        requests.indexWhere((JoinRequestSummary item) => item.id == updated.id);
    if (index >= 0) {
      requests[index] = updated;
    }
    _joinRequestsByGame[gameId] = requests;
  }

  void _adjustCreatedGameAfterModeration(String gameId) {
    final GameDetail current = _details[gameId]!;
    final int approvedCount = _joinRequestsByGame[gameId]!
        .where((JoinRequestSummary item) => item.status == 'APPROVED')
        .length;
    final int pendingCount = _joinRequestsByGame[gameId]!
        .where((JoinRequestSummary item) => item.status == 'PENDING')
        .length;

    _details[gameId] = GameDetail(
      id: current.id,
      title: current.title,
      city: current.city,
      district: current.district,
      venueName: current.venueName,
      venueAddress: current.venueAddress,
      gameDate: current.gameDate,
      startAt: current.startAt,
      endAt: current.endAt,
      skillLevelMin: current.skillLevelMin,
      skillLevelMax: current.skillLevelMax,
      fee: current.fee,
      capacity: current.capacity,
      availableSpots: current.availableSpots - 1,
      courtCount: current.courtCount,
      shuttleType: current.shuttleType,
      approvalMode: current.approvalMode,
      status: current.status,
      host: current.host,
      notes: current.notes,
      joinSummary: GameJoinSummary(
        currentUserStatus: null,
        pendingCount: pendingCount,
        approvedCount: approvedCount,
      ),
    );
  }

  JoinRequestSummary _copyJoinRequest(
    JoinRequestSummary request, {
    required String status,
    required DateTime? respondedAt,
    required DateTime? approvedAt,
    required String? rejectedReason,
  }) {
    return JoinRequestSummary(
      id: request.id,
      gameId: request.gameId,
      userId: request.userId,
      status: status,
      message: request.message,
      respondedAt: respondedAt,
      approvedAt: approvedAt,
      rejectedReason: rejectedReason,
      createdAt: request.createdAt,
      updatedAt: DateTime.parse('2026-03-21T12:00:00+08:00'),
      applicant: request.applicant,
    );
  }
}

class _TimeWindow {
  const _TimeWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
}

_TimeWindow _timeWindowForPreset(GamesFeedTimePreset preset) {
  switch (preset) {
    case GamesFeedTimePreset.any:
      return const _TimeWindow(
        startHour: 0,
        startMinute: 0,
        endHour: 23,
        endMinute: 59,
      );
    case GamesFeedTimePreset.morning:
      return const _TimeWindow(
        startHour: 6,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
      );
    case GamesFeedTimePreset.afternoon:
      return const _TimeWindow(
        startHour: 12,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
      );
    case GamesFeedTimePreset.evening:
      return const _TimeWindow(
        startHour: 18,
        startMinute: 0,
        endHour: 22,
        endMinute: 0,
      );
    case GamesFeedTimePreset.late:
      return const _TimeWindow(
        startHour: 22,
        startMinute: 0,
        endHour: 23,
        endMinute: 59,
      );
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _skillLevelIndex(String level) {
  switch (level) {
    case 'L1':
      return 0;
    case 'L2':
      return 1;
    case 'L3':
      return 2;
    case 'L4':
      return 3;
    case 'L5':
      return 4;
    default:
      return 0;
  }
}

class _JoinRequestLookup {
  const _JoinRequestLookup({
    required this.gameId,
    required this.request,
  });

  final String gameId;
  final JoinRequestSummary request;
}

Finder _verticalScrollableFinder() {
  return find
      .descendant(
        of: find.byType(Scaffold).last,
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down &&
              widget.physics is AlwaysScrollableScrollPhysics,
        ),
      )
      .last;
}

Finder _createTextFieldByLabel(String labelText) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is TextField && widget.decoration?.labelText == labelText;
  });
}

ProfileSession _authenticatedSession() {
  return ProfileSession.authenticated(
    const ProfileUser(
      id: 'user-current',
      nickname: 'Current User',
      avatarUrl: null,
      gender: null,
      skillLevel: 'L3',
      preferredCity: 'Taipei City',
      preferredDistrict: "Da'an",
    ),
    'jwt-token',
  );
}

Widget _buildTestApp({
  ProfileSession? session,
}) {
  final ProfileSession resolvedSession = session ?? _authenticatedSession();

  return ProviderScope(
    overrides: <Override>[
      gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
      profileSessionProvider.overrideWith(
        (Ref ref) async => resolvedSession,
      ),
    ],
    child: const BatDatingApp(),
  );
}

Widget _buildProfilePageTestApp({
  ProfileSession? session,
}) {
  final ProfileSession resolvedSession = session ?? _authenticatedSession();

  return ProviderScope(
    overrides: <Override>[
      gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
      profileSessionProvider.overrideWith(
        (Ref ref) async => resolvedSession,
      ),
    ],
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(1440, 2800),
        devicePixelRatio: 1,
      ),
      child: const MaterialApp(
        home: ProfilePage(),
      ),
    ),
  );
}

Widget _buildCreatePageTestApp({
  ProfileSession? session,
}) {
  final ProfileSession resolvedSession = session ?? _authenticatedSession();

  return ProviderScope(
    overrides: <Override>[
      gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
      profileSessionProvider.overrideWith(
        (Ref ref) async => resolvedSession,
      ),
    ],
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(1440, 10000),
        devicePixelRatio: 1,
      ),
      child: const MaterialApp(
        home: CreateGamePage(),
      ),
    ),
  );
}

Future<void> _openGameRequestsPage(
  WidgetTester tester,
  String gameId,
) async {
  appRouter.go('/my-games/$gameId/requests');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('games discovery renders API data', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Wednesday Doubles'),
      400,
      scrollable: _verticalScrollableFinder(),
    );

    expect(find.text('開放中的球局'), findsOneWidget);
    expect(find.text('Wednesday Doubles'), findsOneWidget);
    expect(find.text("Taipei City · Da'an"), findsOneWidget);
    expect(find.text('Banqiao Rally'), findsOneWidget);
  });

  testWidgets('games discovery filters the feed by city',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('games-filter-city')),
      'New Taipei',
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Banqiao Rally'),
      400,
      scrollable: _verticalScrollableFinder(),
    );

    expect(find.text('Banqiao Rally'), findsOneWidget);
    expect(find.text('Wednesday Doubles'), findsNothing);
    expect(find.text('Friday Packed Session'), findsNothing);
  });

  testWidgets('games discovery hides full games when vacancy only is enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('games-filter-district')),
      'Xinyi',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('games-filter-fee-min')),
      '260',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('games-filter-vacancy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('games-filter-vacancy')));
    await tester.pumpAndSettle();

    expect(find.text('Friday Packed Session'), findsNothing);
    expect(find.text('Wednesday Doubles'), findsNothing);
    expect(find.text('目前沒有即時開放的球局'), findsOneWidget);
  });

  testWidgets('game detail join action updates state',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Wednesday Doubles'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.tap(find.text('Wednesday Doubles'));
    await tester.pumpAndSettle();

    final Finder joinButton = find.widgetWithText(FilledButton, '直接加入');
    await tester.scrollUntilVisible(
      joinButton,
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.ensureVisible(joinButton);
    await tester.pumpAndSettle();
    await tester.tap(joinButton);
    await tester.pumpAndSettle();

    expect(find.text('已成功加入。'), findsOneWidget);
  });

  testWidgets('profile register requires at least one contact field',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildProfilePageTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(ToggleButtons),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('註冊').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'password123',
    );
    await tester.pumpAndSettle();

    final Finder registerButton = find.widgetWithText(FilledButton, '建立帳號');
    await tester.ensureVisible(registerButton);
    await tester.pumpAndSettle();
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Email 或手機至少填一項，才能建立帳號。'),
      findsWidgets,
    );
  });

  testWidgets('create validation blocks invalid numeric input',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildCreatePageTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('費用'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    final Finder feeField = _createTextFieldByLabel('費用');
    expect(feeField, findsOneWidget);

    await tester.enterText(feeField, 'abc');
    await tester.pumpAndSettle();

    final Finder createButton = find.widgetWithText(FilledButton, '建立球局');
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('費用、容量與場地數必須是有效數字。'),
      findsOneWidget,
    );
  });

  testWidgets('my games renders joined and created data',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();

    expect(find.text('已加入清單'), findsOneWidget);
    expect(find.text('我建立的清單'), findsNothing);

    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Friday Night Ladder'),
      400,
      scrollable: _verticalScrollableFinder(),
    );

    expect(find.text('Friday Night Ladder'), findsOneWidget);
    expect(find.text('管理申請'), findsOneWidget);
  });

  testWidgets('my games shows cancelled games consistently',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Saturday Cancelled Session'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saturday Cancelled Session'), findsOneWidget);
    expect(find.text('已取消'), findsWidgets);
  });

  testWidgets('my games shows completed games consistently',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sunday Completed Session'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sunday Completed Session'), findsOneWidget);
    expect(find.text('已結束'), findsWidgets);
  });

  testWidgets('host can review join requests from created games',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await _openGameRequestsPage(tester, 'game-created-001');

    await tester.scrollUntilVisible(
      find.text('Carol'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carol'), findsOneWidget);
    expect(find.text('參加名單'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('join-request-request-001')),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('join-request-request-001')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '接受'), findsNWidgets(2));

    final Finder approveButton = find.widgetWithText(FilledButton, '接受').first;
    await tester.ensureVisible(approveButton);
    await tester.pumpAndSettle();
    await tester.tap(approveButton);
    await tester.pumpAndSettle();

    expect(find.text('申請已接受。'), findsOneWidget);
    expect(find.text('管理申請'), findsNothing);
  });

  testWidgets('host created games keep manage and history actions distinct',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Friday Night Ladder'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('主揪工作台'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('manage-requests-game-created-001')),
      findsOneWidget,
    );
    expect(
      find.textContaining('先處理待審核申請，再看參加名單'),
      findsWidgets,
    );
    expect(find.text('管理申請'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Saturday Cancelled Session'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('已取消'), findsWidgets);
    expect(find.text('查看歷史'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Sunday Completed Session'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('已結束'), findsWidgets);
    expect(find.text('查看歷史'), findsWidgets);
  });

  testWidgets('host can reject join requests from created games',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '我建立的'));
    await tester.pumpAndSettle();

    await _openGameRequestsPage(tester, 'game-created-001');

    await tester.scrollUntilVisible(
      find.text('Ava'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    final Finder rejectButton = find.widgetWithText(OutlinedButton, '拒絕').first;
    await tester.ensureVisible(rejectButton);
    await tester.pumpAndSettle();
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();

    expect(find.text('申請已拒絕。'), findsOneWidget);
  });

  testWidgets('approved game detail keeps contact handoff and status visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/games/game-joined-001');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('已核准，主揪聯絡方式已解鎖'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('已核准，主揪聯絡方式已解鎖'), findsOneWidget);
    expect(find.text('你已被核准加入這場球局，現在可以查看主揪的電話與 LINE ID。'),
        findsOneWidget);
    expect(find.text('電話'), findsOneWidget);
    expect(find.text('LINE ID'), findsOneWidget);
    expect(find.text('0912-345-678'), findsOneWidget);
    expect(find.text('kevin.host'), findsOneWidget);
  });

  testWidgets('guest sees sign-in gate on create page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(session: ProfileSession.guest()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '開團'));
    await tester.pumpAndSettle();

    expect(find.text('訪客無法使用主揪工具'), findsOneWidget);
    expect(find.text('前往登入 / 註冊'), findsOneWidget);
  });

  testWidgets('guest sees sign-in gate on my games page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(session: ProfileSession.guest()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();

    expect(find.text('登入後才會顯示你的行程'), findsOneWidget);
  });

  testWidgets('guest sees sign-in gate on game detail join section',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(session: ProfileSession.guest()),
    );
    await tester.pumpAndSettle();

    appRouter.go('/games/game-open-001');
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('訪客無法使用報名功能'),
      find.byType(Scrollable).last,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入後加入'), findsOneWidget);
  });

  testWidgets('withdrawn game detail shows withdrawn status',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/games/game-withdrawn-001');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('你目前的狀態：已撤回'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('你目前的狀態：已撤回'), findsOneWidget);
    expect(find.text('這場球局已取消，無法再報名。'), findsOneWidget);
  });

  testWidgets('completed game detail shows completed status',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/games/game-completed-001');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('這場球局已結束，無法再報名。'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('這場球局已結束'), findsWidgets);
    expect(find.text('這場球局已結束，無法再報名。'), findsOneWidget);
    expect(find.text('這場球局已結束，已不能再加入。'), findsOneWidget);
  });

  testWidgets('demo preview guest path keeps browse-only review working',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(session: ProfileSession.guest()),
    );
    await tester.pumpAndSettle();

    appRouter.go('/games/game-open-001');
    await tester.pumpAndSettle();

    expect(find.text('球局詳情'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('訪客無法使用報名功能'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('球局詳情'), findsOneWidget);
    expect(find.text('訪客無法使用報名功能'), findsOneWidget);
    expect(find.text('登入後加入'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, '開團'));
    await tester.pumpAndSettle();
    expect(find.text('訪客無法使用主揪工具'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, '我的球局'));
    await tester.pumpAndSettle();
    expect(find.text('登入後才會顯示你的行程'), findsOneWidget);
  });

  testWidgets('demo preview host path keeps review and contact handoff working',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/my-games/game-created-001/requests');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Carol'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('參加名單'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('pending-requests-card')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Ava'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ava'), findsOneWidget);

    appRouter.go('/games/game-joined-001');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('已核准，主揪聯絡方式已解鎖'),
      400,
      scrollable: _verticalScrollableFinder(),
    );
    await tester.pumpAndSettle();

    expect(find.text('已核准，主揪聯絡方式已解鎖'), findsOneWidget);
    expect(find.text('電話'), findsOneWidget);
    expect(find.text('LINE ID'), findsOneWidget);
    expect(find.text('0912-345-678'), findsOneWidget);
    expect(find.text('kevin.host'), findsOneWidget);
  });
}
