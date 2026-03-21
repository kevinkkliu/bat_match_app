import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Map<String, String> headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (AppConfig.devUserEmail.isNotEmpty) {
    headers['x-dev-user-email'] = AppConfig.devUserEmail;
  }

  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: headers,
    ),
  );
});
