import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';

/// 購入結果。トライアルとして開始された場合は[isTrial]がtrue、
/// [trialEndsAt]にRevenueCatが確定したトライアル終了時刻(entitlementの
/// expirationDate)が入る——14日を自前計算しない。
class PurchaseResult {
  final bool granted;
  final bool isTrial;
  final DateTime? trialEndsAt;

  const PurchaseResult({
    required this.granted,
    this.isTrial = false,
    this.trialEndsAt,
  });
}

/// RevenueCat SDKへの薄いラッパー。APIキーが未設定（開発初期や設定忘れ）の場合は
/// 何もせず、常に「Pro未加入」として振る舞う（課金機能なしで安全に動く）。
class PurchaseService {
  PurchaseService._internal();
  static final PurchaseService instance = PurchaseService._internal();

  bool _configured = false;

  bool get _supportedPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  String get _apiKeyForPlatform {
    if (!_supportedPlatform) return '';
    if (Platform.isIOS) return RevenueCatConfig.iosApiKey;
    if (Platform.isAndroid) return RevenueCatConfig.androidApiKey;
    return '';
  }

  bool get isAvailable => _configured;

  /// [appUserId]にはFirebase AuthのUIDを渡す。RevenueCat側のユーザーIDを
  /// Firebaseのuidに揃えておくことで、サーバー側（Cloud Functions経由のWebhook）から
  /// 同じuidでPro状態をFirestoreに反映できる。
  Future<void> initialize({required String appUserId}) async {
    if (_configured || !_supportedPlatform) return;
    final apiKey = _apiKeyForPlatform;
    if (apiKey.isEmpty) return;

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId;
      await Purchases.configure(configuration);
      _configured = true;
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
    }
  }

  Future<bool> hasProEntitlement() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(
        RevenueCatConfig.proEntitlementId,
      );
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo failed: $e');
      return false;
    }
  }

  /// Pro機能のうち、写真・動画のクラウド同期だけはサブスク（月額/年額）限定で、
  /// 買い切りプランの購入者には提供しない（継続的なストレージコストが発生する
  /// 機能を、単発の売り切り収益だけで無期限に賄うのを避けるため）。買い切り購入は
  /// 有効期限のないエンタイトルメントとして付与されるため、[expirationDate]の
  /// 有無でサブスクかどうかを判定できる。
  Future<bool> hasMediaSyncEntitlement() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement =
          info.entitlements.active[RevenueCatConfig.proEntitlementId];
      return entitlement != null && entitlement.expirationDate != null;
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo failed: $e');
      return false;
    }
  }

  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (!_configured) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  Future<Offering?> fetchCurrentOffering() async {
    if (!_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint('RevenueCat getOfferings failed: $e');
      return null;
    }
  }

  /// 追加60分パックのように、現在のOfferingの中から特定の商品IDを持つ
  /// Packageを1つ探す（サブスク/買い切りの3枠固定レイアウトである
  /// PaywallScreenとは別の、消費型IAP専用の小さな購入画面から使う）。
  Future<Package?> findPackageByProductId(String productId) async {
    final offering = await fetchCurrentOffering();
    if (offering == null) return null;
    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == productId) return package;
    }
    return null;
  }

  /// 消費型IAP（追加分数パックなど）の購入。サブスク/買い切りと違い
  /// エンタイトルメントが付与されないため、[purchasePackage]のような
  /// entitlement判定はできない——例外が投げられなければ購入成功とみなす。
  /// 実際の残高反映はRevenueCat Webhook経由でサーバー側が行うため、ここでは
  /// StoreKit/Play課金が完了したことだけを確認する。
  ///
  /// 戻り値: 購入成功ならtrue、ユーザーが自分でキャンセルしたならfalse
  /// （エラー扱いしない）。それ以外の失敗は例外をそのまま投げる。
  Future<bool> purchaseConsumable(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// 購入成功でPro付与済みなら[PurchaseResult]を返す。ユーザーが自分で
  /// キャンセルした場合はnullを返す（エラー扱いしない）。それ以外の失敗は
  /// 例外をそのまま投げる。
  Future<PurchaseResult?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final entitlement = result.customerInfo.entitlements.active[
          RevenueCatConfig.proEntitlementId];
      if (entitlement == null) return const PurchaseResult(granted: false);
      final isTrial = entitlement.periodType == PeriodType.trial;
      final trialEndsAt = isTrial && entitlement.expirationDate != null
          ? DateTime.parse(entitlement.expirationDate!)
          : null;
      return PurchaseResult(
        granted: true,
        isTrial: isTrial,
        trialEndsAt: trialEndsAt,
      );
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      rethrow;
    }
  }

  /// 指定した商品IDそれぞれについて、トライアル/導入価格の適格性を返す。
  ///
  /// [Purchases.checkTrialOrIntroductoryPriceEligibility]はiOS専用のAPIで、
  /// Androidは常に`introEligibilityStatusUnknown`しか返さない（RevenueCat側の
  /// 既知の制約）。そのためAndroidでは全商品を「適格」として扱う——Play Billing
  /// 自体が同一アカウントへの二重トライアル付与を防ぐため、表示だけの問題で
  /// 実害はない。iOS側は「適格」と明確に判定できた商品だけをtrueとし、
  /// 不明・不適格・オファーなしはすべてfalse（トライアル文言を隠す安全側）。
  Future<Map<String, bool>> checkTrialEligibility(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};
    if (!Platform.isIOS) {
      return {for (final id in productIds) id: true};
    }
    try {
      final result =
          await Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);
      return {
        for (final id in productIds)
          id: result[id]?.status ==
              IntroEligibilityStatus.introEligibilityStatusEligible,
      };
    } catch (e) {
      debugPrint('RevenueCat checkTrialOrIntroductoryPriceEligibility failed: $e');
      return {for (final id in productIds) id: false};
    }
  }

  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(
      RevenueCatConfig.proEntitlementId,
    );
  }

  /// メールアカウントのサインアップ/サインイン/サインアウトに合わせて、RevenueCat側の
  /// 識別ユーザーをFirebase Authのuidに揃える。[Purchases.logOut]は使わない —
  /// ランダムな匿名IDが新規発行されてしまい、Cloud Functions側（isProUser）が
  /// 参照するFirebase uidとズレてしまうため、常に[Purchases.logIn]だけを使う。
  Future<void> switchAppUserId(String uid) async {
    if (!_configured) return;
    try {
      if (await Purchases.appUserID == uid) return;
      await Purchases.logIn(uid);
    } catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
    }
  }
}
