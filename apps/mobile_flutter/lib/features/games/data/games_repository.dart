import 'package:dio/dio.dart';

import '../../../shared/models/game_summary.dart';

enum GamesFeedTimePreset {
  any,
  morning,
  afternoon,
  evening,
  late,
}

const Object _gamesFeedUnset = Object();

class GamesFeedQuery {
  const GamesFeedQuery({
    this.city = '',
    this.district = '',
    this.date,
    this.timePreset = GamesFeedTimePreset.any,
    this.skillLevel = '',
    this.feeMin,
    this.feeMax,
    this.vacancyOnly = false,
    this.page = 1,
    this.pageSize = 20,
  });

  final String city;
  final String district;
  final DateTime? date;
  final GamesFeedTimePreset timePreset;
  final String skillLevel;
  final int? feeMin;
  final int? feeMax;
  final bool vacancyOnly;
  final int page;
  final int pageSize;

  bool get hasActiveFilters {
    return city.trim().isNotEmpty ||
        district.trim().isNotEmpty ||
        date != null ||
        timePreset != GamesFeedTimePreset.any ||
        skillLevel.trim().isNotEmpty ||
        feeMin != null ||
        feeMax != null ||
        vacancyOnly;
  }

  GamesFeedQuery copyWith({
    String? city,
    String? district,
    DateTime? date,
    GamesFeedTimePreset? timePreset,
    String? skillLevel,
    Object? feeMin = _gamesFeedUnset,
    Object? feeMax = _gamesFeedUnset,
    bool? vacancyOnly,
    int? page,
    int? pageSize,
  }) {
    return GamesFeedQuery(
      city: city ?? this.city,
      district: district ?? this.district,
      date: date ?? this.date,
      timePreset: timePreset ?? this.timePreset,
      skillLevel: skillLevel ?? this.skillLevel,
      feeMin: feeMin == _gamesFeedUnset ? this.feeMin : feeMin as int?,
      feeMax: feeMax == _gamesFeedUnset ? this.feeMax : feeMax as int?,
      vacancyOnly: vacancyOnly ?? this.vacancyOnly,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    final String normalizedCity = city.trim();
    if (normalizedCity.isNotEmpty) {
      query['city'] = normalizedCity;
    }

    final String normalizedDistrict = district.trim();
    if (normalizedDistrict.isNotEmpty) {
      query['district'] = normalizedDistrict;
    }

    if (date != null) {
      query['date'] = _formatDate(date!);
      final _TimeWindow? timeWindow = _timeWindowForPreset(timePreset);
      if (timeWindow != null) {
        query['startAtFrom'] = _combineDateAndTime(
                date!, timeWindow.startHour, timeWindow.startMinute)
            .toUtc()
            .toIso8601String();
        query['startAtTo'] =
            _combineDateAndTime(date!, timeWindow.endHour, timeWindow.endMinute)
                .toUtc()
                .toIso8601String();
      }
    }

    final String normalizedSkillLevel = skillLevel.trim();
    if (normalizedSkillLevel.isNotEmpty) {
      query['skillLevel'] = normalizedSkillLevel;
    }

    if (feeMin != null) {
      query['feeMin'] = feeMin;
    }

    if (feeMax != null) {
      query['feeMax'] = feeMax;
    }

    if (vacancyOnly) {
      query['vacancyOnly'] = true;
    }

    return query;
  }

  @override
  bool operator ==(Object other) {
    return other is GamesFeedQuery &&
        other.city == city &&
        other.district == district &&
        other.date == date &&
        other.timePreset == timePreset &&
        other.skillLevel == skillLevel &&
        other.feeMin == feeMin &&
        other.feeMax == feeMax &&
        other.vacancyOnly == vacancyOnly &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      city,
      district,
      date,
      timePreset,
      skillLevel,
      feeMin,
      feeMax,
      vacancyOnly,
      page,
      pageSize,
    );
  }
}

class CreateGameInput {
  const CreateGameInput({
    required this.title,
    required this.city,
    required this.district,
    required this.venueName,
    required this.venueAddress,
    required this.gameDate,
    required this.startAt,
    required this.endAt,
    required this.skillLevelMin,
    required this.skillLevelMax,
    required this.fee,
    required this.capacity,
    required this.courtCount,
    required this.shuttleType,
    required this.approvalMode,
    required this.notes,
  });

  final String title;
  final String city;
  final String district;
  final String venueName;
  final String venueAddress;
  final String gameDate;
  final String startAt;
  final String endAt;
  final String skillLevelMin;
  final String? skillLevelMax;
  final int fee;
  final int capacity;
  final int courtCount;
  final String? shuttleType;
  final String approvalMode;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'city': city,
      'district': district,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'gameDate': gameDate,
      'startAt': startAt,
      'endAt': endAt,
      'skillLevelMin': skillLevelMin,
      'skillLevelMax': skillLevelMax,
      'fee': fee,
      'capacity': capacity,
      'courtCount': courtCount,
      'shuttleType': shuttleType,
      'approvalMode': approvalMode,
      'notes': notes,
    };
  }
}

class JoinRequestSummary {
  const JoinRequestSummary({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.status,
    required this.message,
    required this.respondedAt,
    required this.approvedAt,
    required this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
    required this.applicant,
  });

  factory JoinRequestSummary.fromJson(Map<String, dynamic> json) {
    return JoinRequestSummary(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
      respondedAt: _parseDateTime(json['respondedAt']),
      approvedAt: _parseDateTime(json['approvedAt']),
      rejectedReason: json['rejectedReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      applicant: json['applicant'] == null
          ? null
          : JoinRequestApplicant.fromJson(
              Map<String, dynamic>.from(json['applicant'] as Map),
            ),
    );
  }

  final String id;
  final String gameId;
  final String userId;
  final String status;
  final String? message;
  final DateTime? respondedAt;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JoinRequestApplicant? applicant;

  bool get isPending => status == 'PENDING';

  bool get isApproved => status == 'APPROVED';

  bool get isRejected => status == 'REJECTED';

  bool get isWithdrawn => status == 'WITHDRAWN' || status == 'CANCELLED';
}

class JoinRequestApplicant {
  const JoinRequestApplicant({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.skillLevel,
    required this.preferredCity,
    required this.preferredDistrict,
  });

  factory JoinRequestApplicant.fromJson(Map<String, dynamic> json) {
    return JoinRequestApplicant(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      skillLevel: json['skillLevel'] as String,
      preferredCity: json['preferredCity'] as String?,
      preferredDistrict: json['preferredDistrict'] as String?,
    );
  }

  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? gender;
  final String skillLevel;
  final String? preferredCity;
  final String? preferredDistrict;
}

class GameMutationSummary {
  const GameMutationSummary({
    required this.id,
    required this.availableSpots,
    required this.status,
  });

  factory GameMutationSummary.fromJson(Map<String, dynamic> json) {
    return GameMutationSummary(
      id: json['id'] as String,
      availableSpots: (json['availableSpots'] as num).toInt(),
      status: json['status'] as String,
    );
  }

  final String id;
  final int availableSpots;
  final String status;
}

class GameJoinResult {
  const GameJoinResult({
    required this.joinRequest,
    required this.game,
  });

  factory GameJoinResult.fromJson(Map<String, dynamic> json) {
    return GameJoinResult(
      joinRequest: JoinRequestSummary.fromJson(
          Map<String, dynamic>.from(json['joinRequest'] as Map)),
      game: GameMutationSummary.fromJson(
          Map<String, dynamic>.from(json['game'] as Map)),
    );
  }

  final JoinRequestSummary joinRequest;
  final GameMutationSummary game;
}

class GamesRepository {
  GamesRepository(this._dio);

  final Dio _dio;

  Future<PaginatedGames<GameSummary>> fetchGames({
    GamesFeedQuery query = const GamesFeedQuery(),
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/games',
      queryParameters: query.toQueryParameters(),
    );

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(response.data as Map);
    final List<dynamic> items =
        (data['items'] as List<dynamic>? ?? <dynamic>[]);

    return PaginatedGames<GameSummary>(
      items: items
          .map((dynamic item) =>
              GameSummary.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      page: (data['page'] as num?)?.toInt() ?? query.page,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? query.pageSize,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<GameDetail> fetchGameDetail(String gameId) async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/api/v1/games/$gameId');
    return GameDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<GameDetail> createGame(CreateGameInput input) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/games',
      data: input.toJson(),
    );

    return GameDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<GameJoinResult> joinGame(
    String gameId, {
    String? message,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (message != null && message.trim().isNotEmpty) {
      payload['message'] = message.trim();
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/games/$gameId/join',
      data: payload,
    );

    return GameJoinResult.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<JoinRequestSummary>> fetchGameJoinRequests(String gameId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/games/$gameId/join-requests',
    );
    return _parseJoinRequestList(response.data);
  }

  Future<JoinRequestSummary> approveJoinRequest(String joinRequestId) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/join-requests/$joinRequestId/approve',
    );
    return JoinRequestSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<JoinRequestSummary> rejectJoinRequest(
    String joinRequestId, {
    String? reason,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (reason != null && reason.trim().isNotEmpty) {
      payload['reason'] = reason.trim();
    }

    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/join-requests/$joinRequestId/reject',
      data: payload,
    );
    return JoinRequestSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<JoinRequestSummary> withdrawJoinRequestForGame(String gameId) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/join-requests/game/$gameId/withdraw',
    );
    return JoinRequestSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<GameDetail> updateGame(
    String gameId, {
    String? title,
    int? fee,
    int? capacity,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }
    if (fee != null) {
      payload['fee'] = fee;
    }
    if (capacity != null) {
      payload['capacity'] = capacity;
    }
    if (notes != null) {
      payload['notes'] = notes.trim().isEmpty ? null : notes.trim();
    }

    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/games/$gameId',
      data: payload,
    );

    return GameDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<GameDetail> updateGameStatus(
    String gameId,
    String status,
  ) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/games/$gameId/status',
      data: <String, dynamic>{'status': status},
    );

    return GameDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<GameSummary>> fetchJoinedGames() async {
    return _fetchMyGames('/api/v1/me/games/joined');
  }

  Future<List<GameSummary>> fetchCreatedGames() async {
    return _fetchMyGames('/api/v1/me/games/created');
  }

  Future<List<GameSummary>> _fetchMyGames(String path) async {
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return _parseGameList(response.data);
  }

  List<GameSummary> _parseGameList(dynamic raw) {
    final List<dynamic> items = raw is Map
        ? (Map<String, dynamic>.from(raw)['items'] as List<dynamic>? ??
            <dynamic>[])
        : raw as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (dynamic item) =>
              GameSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  List<JoinRequestSummary> _parseJoinRequestList(dynamic raw) {
    final List<dynamic> items = raw is Map
        ? (Map<String, dynamic>.from(raw)['items'] as List<dynamic>? ??
            <dynamic>[])
        : raw as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (dynamic item) => JoinRequestSummary.fromJson(
              Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.parse(value as String);
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

_TimeWindow? _timeWindowForPreset(GamesFeedTimePreset preset) {
  switch (preset) {
    case GamesFeedTimePreset.any:
      return null;
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

DateTime _combineDateAndTime(DateTime date, int hour, int minute) {
  return DateTime(date.year, date.month, date.day, hour, minute);
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
