import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';

class ProfileUser {
  const ProfileUser({
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

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
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

  factory ProfileUser.guest() {
    return const ProfileUser(
      id: 'guest',
      nickname: '訪客',
      avatarUrl: null,
      gender: null,
      skillLevel: 'L1',
      preferredCity: null,
      preferredDistrict: null,
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

enum ProfileSessionMode {
  guest,
  preview,
  authenticated,
}

class ProfileSession {
  const ProfileSession({
    required this.user,
    required this.token,
    required this.mode,
  });

  factory ProfileSession.guest() {
    return ProfileSession(
      user: ProfileUser.guest(),
      token: null,
      mode: ProfileSessionMode.guest,
    );
  }

  factory ProfileSession.preview(ProfileUser user) {
    return ProfileSession(
      user: user,
      token: null,
      mode: ProfileSessionMode.preview,
    );
  }

  factory ProfileSession.authenticated(ProfileUser user, String token) {
    return ProfileSession(
      user: user,
      token: token,
      mode: ProfileSessionMode.authenticated,
    );
  }

  final ProfileUser user;
  final String? token;
  final ProfileSessionMode mode;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isGuest => mode == ProfileSessionMode.guest;
  bool get isPreview => mode == ProfileSessionMode.preview;
  bool get hasServerIdentity => !isGuest;
}

class ProfileRegisterInput {
  const ProfileRegisterInput({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.nickname,
    required this.skillLevel,
  });

  final String email;
  final String phoneNumber;
  final String password;
  final String nickname;
  final String skillLevel;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
      'password': password,
      'nickname': nickname.trim(),
      'skillLevel': skillLevel,
    };
  }
}

class ProfileLoginInput {
  const ProfileLoginInput({
    required this.emailOrPhone,
    required this.password,
  });

  final String emailOrPhone;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'emailOrPhone': emailOrPhone.trim(),
      'password': password,
    };
  }
}

class ProfileUpdateInput {
  const ProfileUpdateInput({
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.skillLevel,
    required this.preferredCity,
    required this.preferredDistrict,
    this.lineId,
  });

  final String nickname;
  final String avatarUrl;
  final String gender;
  final String skillLevel;
  final String preferredCity;
  final String preferredDistrict;
  final String? lineId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
      if (avatarUrl.trim().isNotEmpty) 'avatarUrl': avatarUrl.trim(),
      if (gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (skillLevel.trim().isNotEmpty) 'skillLevel': skillLevel.trim(),
      if (preferredCity.trim().isNotEmpty) 'preferredCity': preferredCity.trim(),
      if (preferredDistrict.trim().isNotEmpty) 'preferredDistrict': preferredDistrict.trim(),
      if (lineId != null && lineId!.trim().isNotEmpty) 'lineId': lineId!.trim(),
    };
  }
}

class ProfileRepository {
  ProfileRepository(this._dio, this._storage);

  static const String tokenStorageKey = 'bat_dating_auth_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<ProfileSession> loadSession() async {
    final String? token = await _storage.read(key: tokenStorageKey);

    if (token == null || token.isEmpty) {
      if (AppConfig.devUserEmail.isEmpty) {
        return ProfileSession.guest();
      }

      final ProfileUser user = await fetchCurrentUser();
      return ProfileSession.preview(user);
    }

    try {
      final ProfileUser user = await fetchCurrentUser(token: token);
      return ProfileSession.authenticated(user, token);
    } on DioException catch (error) {
      if (_isUnauthorized(error)) {
        await clearSession();

        if (AppConfig.devUserEmail.isEmpty) {
          return ProfileSession.guest();
        }

        final ProfileUser user = await fetchCurrentUser();
        return ProfileSession.preview(user);
      }

      rethrow;
    }
  }

  Future<ProfileSession> register(ProfileRegisterInput input) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/auth/register',
      data: input.toJson(),
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
    final ProfileSession session = ProfileSession.authenticated(
      ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      data['token'] as String,
    );

    await _storage.write(key: tokenStorageKey, value: session.token);
    return session;
  }

  Future<ProfileSession> login(ProfileLoginInput input) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/auth/login',
      data: input.toJson(),
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
    final ProfileSession session = ProfileSession.authenticated(
      ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      data['token'] as String,
    );

    await _storage.write(key: tokenStorageKey, value: session.token);
    return session;
  }

  Future<ProfileUser> fetchCurrentUser({String? token}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/auth/me',
      options: _authOptions(token),
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
    return ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<ProfileUser> updateCurrentUser(
    ProfileUpdateInput input, {
    String? token,
  }) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/api/v1/users/me',
      data: input.toJson(),
      options: _authOptions(token),
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
    return ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: tokenStorageKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenStorageKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: tokenStorageKey);
  }

  Options? _authOptions(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer $token',
      },
    );
  }

  bool _isUnauthorized(DioException error) {
    final int? statusCode = error.response?.statusCode;
    return statusCode == 401;
  }
}
