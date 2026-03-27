class GameHostSummary {
  const GameHostSummary({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.skillLevel,
    required this.preferredCity,
    required this.preferredDistrict,
    this.phoneNumber,
    this.lineId,
  });

  factory GameHostSummary.fromJson(Map<String, dynamic> json) {
    return GameHostSummary(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      skillLevel: json['skillLevel'] as String,
      preferredCity: json['preferredCity'] as String?,
      preferredDistrict: json['preferredDistrict'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      lineId: json['lineId'] as String?,
    );
  }

  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? gender;
  final String skillLevel;
  final String? preferredCity;
  final String? preferredDistrict;
  final String? phoneNumber;
  final String? lineId;
}

class GameSummary {
  const GameSummary({
    required this.id,
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
    required this.availableSpots,
    required this.courtCount,
    required this.shuttleType,
    required this.approvalMode,
    required this.status,
    required this.host,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      venueName: json['venueName'] as String,
      venueAddress: json['venueAddress'] as String,
      gameDate: DateTime.parse(json['gameDate'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      skillLevelMin: json['skillLevelMin'] as String,
      skillLevelMax: json['skillLevelMax'] as String?,
      fee: (json['fee'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      availableSpots: (json['availableSpots'] as num).toInt(),
      courtCount: (json['courtCount'] as num).toInt(),
      shuttleType: json['shuttleType'] as String?,
      approvalMode: json['approvalMode'] as String,
      status: json['status'] as String,
      host: GameHostSummary.fromJson(json['host'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String title;
  final String city;
  final String district;
  final String venueName;
  final String venueAddress;
  final DateTime gameDate;
  final DateTime startAt;
  final DateTime endAt;
  final String skillLevelMin;
  final String? skillLevelMax;
  final int fee;
  final int capacity;
  final int availableSpots;
  final int courtCount;
  final String? shuttleType;
  final String approvalMode;
  final String status;
  final GameHostSummary host;

  bool get isOpen => status == 'OPEN';
  bool get isFull => status == 'FULL' || availableSpots <= 0;
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isHistorical => isCancelled || isCompleted;
  bool get isClosedForJoin => isFull || isHistorical || !isOpen;
}

class GameJoinSummary {
  const GameJoinSummary({
    required this.currentUserStatus,
    required this.pendingCount,
    required this.approvedCount,
  });

  factory GameJoinSummary.fromJson(Map<String, dynamic> json) {
    return GameJoinSummary(
      currentUserStatus: json['currentUserStatus'] as String?,
      pendingCount: (json['pendingCount'] as num).toInt(),
      approvedCount: (json['approvedCount'] as num).toInt(),
    );
  }

  final String? currentUserStatus;
  final int pendingCount;
  final int approvedCount;
}

class GameDetail extends GameSummary {
  const GameDetail({
    required super.id,
    required super.title,
    required super.city,
    required super.district,
    required super.venueName,
    required super.venueAddress,
    required super.gameDate,
    required super.startAt,
    required super.endAt,
    required super.skillLevelMin,
    required super.skillLevelMax,
    required super.fee,
    required super.capacity,
    required super.availableSpots,
    required super.courtCount,
    required super.shuttleType,
    required super.approvalMode,
    required super.status,
    required super.host,
    required this.notes,
    required this.joinSummary,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    final summary = GameSummary.fromJson(json);
    return GameDetail(
      id: summary.id,
      title: summary.title,
      city: summary.city,
      district: summary.district,
      venueName: summary.venueName,
      venueAddress: summary.venueAddress,
      gameDate: summary.gameDate,
      startAt: summary.startAt,
      endAt: summary.endAt,
      skillLevelMin: summary.skillLevelMin,
      skillLevelMax: summary.skillLevelMax,
      fee: summary.fee,
      capacity: summary.capacity,
      availableSpots: summary.availableSpots,
      courtCount: summary.courtCount,
      shuttleType: summary.shuttleType,
      approvalMode: summary.approvalMode,
      status: summary.status,
      host: summary.host,
      notes: json['notes'] as String?,
      joinSummary:
          GameJoinSummary.fromJson(json['joinSummary'] as Map<String, dynamic>),
    );
  }

  final String? notes;
  final GameJoinSummary joinSummary;
}

class PaginatedGames<T> {
  const PaginatedGames({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
}
