class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String devUserEmail = String.fromEnvironment(
    'DEV_USER_EMAIL',
    defaultValue: '',
  );
}
