import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
import '../services/purchase_service.dart';

/// アプリ全体でのPro加入状態。RevenueCatからのリアルタイム更新（購入・復元・
/// 有効期限切れなど）を受けて自動的に反映される。
class SubscriptionStore extends ChangeNotifier {
  final PurchaseService _purchases = PurchaseService.instance;

  bool isPro = false;
  bool loading = true;

  void Function(CustomerInfo)? _listener;

  Future<void> initialize(String appUserId) async {
    await _purchases.initialize(appUserId: appUserId);
    _listener = (info) {
      final active = info.entitlements.active.containsKey(
        RevenueCatConfig.proEntitlementId,
      );
      if (active != isPro) {
        isPro = active;
        notifyListeners();
      }
    };
    _purchases.addCustomerInfoListener(_listener!);

    isPro = await _purchases.hasProEntitlement();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    isPro = await _purchases.hasProEntitlement();
    notifyListeners();
  }

  Future<bool> restore() async {
    final restored = await _purchases.restorePurchases();
    isPro = restored;
    notifyListeners();
    return restored;
  }

  /// メールアカウントのサインアップ/サインイン/サインアウト後に呼ぶ。RevenueCat側の
  /// ユーザーをFirebase Authの新しいuidに揃え、Pro状態を再取得する。
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
