import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations();

  static const Locale zhTw = Locale('zh', 'TW');
  static const List<Locale> supportedLocales = <Locale>[zhTw];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);

    if (localizations == null) {
      throw FlutterError(
        'AppLocalizations are not available in this context.',
      );
    }

    return localizations;
  }

  String get appTitle => '台灣羽球約會';
  String get appShortName => '羽球零打';
  String get loading => '載入中...';
  String get guestMode => '訪客模式';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(const AppLocalizations());
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
