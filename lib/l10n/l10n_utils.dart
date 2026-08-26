import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// [BuildContext]を持たないサービス層（[ReminderService]、[BackendService]など）が
/// 通知文言・エラーメッセージを組み立てる際に使う、端末の言語設定ベースのローカライズ。
AppLocalizations currentLocalizations() {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final locale = deviceLocale.languageCode == 'ja'
      ? const Locale('ja')
      : const Locale('en');
  return lookupAppLocalizations(locale);
}
