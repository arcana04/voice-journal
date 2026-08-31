import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
import '../services/purchase_service.dart';

/// アプリ全体でのPro加入状態。RevenueCatからのリアルタイム更新（購入・復元・
/// 有効期限切れなど）を受けて自動的に反映される。
class SubscriptionStore extends ChangeNotifier {
  final PurchaseService _purchases = PurchaseService.instance;

  bool isPro = false;

  /// 写真・動画のクラウド同期が使えるかどうか。買い切りプランはPro機能の大半が
  /// 使えるが、これだけはサブスク（月額/年額）限定（[[isPro]]がtrueでも
  /// falseになりうる）。
  bool isProWithMediaSync = false;
  bool loading = true;

  void Function(CustomerInfo)? _listener;

  Future<void> _refreshFromCustomerInfo(CustomerInfo info) async {
    // 本番課金基盤（RevenueCat本番キー/Webhook等）が未整備で、開発者自身も
    // 実際に課金してPro機能を確認する手段が無いため、デバッグビルドでは常に
    // Pro扱いにする。リリース/TestFlightビルドには影響しない。
    if (kDebugMode) {
      if (!isPro || !isProWithMediaSync) {
        isPro = true;
        isProWithMediaSync = true;
        notifyListeners();
      }
      return;
    }
    final active = info.entitlements.active.containsKey(
      RevenueCatConfig.proEntitlementId,
    );
    final entitlement =
        info.entitlements.active[RevenueCatConfig.proEntitlementId];
    final withMediaSync = entitlement != null && entitlement.expirationDate != null;
    if (active != isPro || withMediaSync != isProWithMediaSync) {
      isPro = active;
      isProWithMediaSync = withMediaSync;
      notifyListeners();
    }
  }

  Future<void> initialize(String appUserId) async {
    await _purchases.initialize(appUserId: appUserId);
    _listener = (info) {
      unawaited(_refreshFromCustomerInfo(info));
    };
    _purchases.addCustomerInfoListener(_listener!);

    await refresh();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (kDebugMode) {
      isPro = true;
      isProWithMediaSync = true;
      notifyListeners();
      return;
    }
    isPro = await _purchases.hasProEntitlement();
    isProWithMediaSync = await _purchases.hasMediaSyncEntitlement();
    notifyListeners();
  }

  Future<bool> restore() async {
    final restored = await _purchases.restorePurchases();
    await refresh();
    return restored;
  }

  /// メールアカウントのサインアップ/サインイン/サインアウト後に呼ぶ。RevenueCat側の
  /// ユーザーを新しいuidに揃え、Pro状態を再取得する。
  Future<void> switchUser(String uid) async {
    await _purchases.switchAppUserId(uid);
    await refresh();
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      _purchases.removeCustomerInfoListener(listener);
    }
    super.dispose();
  }
}
