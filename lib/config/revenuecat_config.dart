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

  /// 月間録音時間の上限超過時に購入できる消費型IAP「追加60分パック」の
  /// 商品ID。App Store Connect/RevenueCat側の商品IDと完全に一致させること
  /// （`functions/src/index.ts`の`EXTRA_MINUTES_PACK_PRODUCT_ID`と同じ値）。
  /// 過去に月額プランのApple Product Id不一致で価格取得に失敗したバグが
  /// あるため、ここは特に慎重に。エンタイトルメントは持たない（消費型のため）。
  static const String extraMinutesPackProductId =
      'com.arcana04.voicejournal.extra_minutes_60';
}
