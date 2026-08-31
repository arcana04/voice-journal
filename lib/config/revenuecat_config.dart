/// RevenueCatのAPIキーはリポジトリに含めず、ビルド時に
/// `--dart-define=REVENUECAT_IOS_API_KEY=...` のように渡す（Codemagicのビルド設定側で
/// 環境変数から注入する想定）。未設定のままなら[PurchaseService]は何もせず、
/// 課金機能は無効（＝全員無料プラン扱い）のまま安全に動作する。
class RevenueCatConfig {
  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  /// RevenueCatダッシュボードで作成する「Pro」プランのエンタイトルメントID。
  static const String proEntitlementId = 'voice_journal_pro';
}
