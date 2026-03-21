import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.skillLevel,
    required this.preferredCity,
    required this.preferredDistrict,
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

class ProfileSession {
  const ProfileSession({
    required this.user,
    required this.token,
  });

  final ProfileUser user;
  final String? token;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
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
  });

  final String nickname;
  final String avatarUrl;
  final String gender;
  final String skillLevel;
  final String preferredCity;
  final String preferredDistrict;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
      if (avatarUrl.trim().isNotEmpty) 'avatarUrl': avatarUrl.trim(),
      if (gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (skillLevel.trim().isNotEmpty) 'skillLevel': skillLevel.trim(),
      if (preferredCity.trim().isNotEmpty) 'preferredCity': preferredCity.trim(),
      if (preferredDistrict.trim().isNotEmpty) 'preferredDistrict': preferredDistrict.trim(),
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
      final ProfileUser user = await fetchCurrentUser();
      return ProfileSession(user: user, token: null);
    }

    try {
      final ProfileUser user = await fetchCurrentUser(token: token);
      return ProfileSession(user: user, token: token);
    } on DioException catch (error) {
      if (_isUnauthorized(error)) {
        await clearSession();
        final ProfileUser user = await fetchCurrentUser();
        return ProfileSession(user: user, token: null);
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
    final ProfileSession session = ProfileSession(
      user: ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      token: data['token'] as String,
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
    final ProfileSession session = ProfileSession(
      user: ProfileUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      token: data['token'] as String,
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
        'x-dev-user-email': '',
      },
    );
  }

  bool _isUnauthorized(DioException error) {
    final int? statusCode = error.response?.statusCode;
    return statusCode == 401;
  }
}
