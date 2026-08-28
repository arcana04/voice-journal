import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';

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

  /// 購入成功でPro付与済みならtrue。ユーザーが自分でキャンセルした場合はnullを返す
  /// （エラー扱いしない）。それ以外の失敗は例外をそのまま投げる。
  Future<bool?> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return info.entitlements.active.containsKey(
        RevenueCatConfig.proEntitlementId,
      );
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      rethrow;
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
