import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

const String _authTokenStorageKey = 'bat_dating_auth_token';

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Map<String, String> headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (AppConfig.devUserEmail.isNotEmpty) {
    headers['x-dev-user-email'] = AppConfig.devUserEmail;
  }

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: headers,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final String? token = await storage.read(key: _authTokenStorageKey);

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});
