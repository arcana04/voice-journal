import 'package:cloud_firestore/cloud_firestore.dart';

/// 買い切りプランの先着100人限定枠。実際のカウントはCloud Functions
/// (`revenueCatWebhook`)がNON_RENEWING_PURCHASEイベント受信時にサーバー側で
/// `counters/lifetimePurchases.count`へ加算する。クライアントはこのドキュメントを
/// 読むだけで、書き込み権限は無い（firestore.rules参照）。
class LifetimePlanService {
  LifetimePlanService._internal();
  static final LifetimePlanService instance = LifetimePlanService._internal();

  static const int cap = 100;

  /// 残り購入可能枠数。読み取りに失敗した場合はnullを返す
  /// （呼び出し側は「不明」として扱い、誤った数字を表示しない）。
  Future<int?> remainingSlots() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('counters')
          .doc('lifetimePurchases')
          .get();
      final count = (snap.data()?['count'] as num?)?.toInt() ?? 0;
      return (cap - count).clamp(0, cap);
    } catch (_) {
      return null;
    }
  }

  /// 買い切りプランがまだ購入可能かどうか。読み取りに失敗した場合は
  /// 「100人限定」という約束を破らないよう、安全側（購入不可）に倒す。
  Future<bool> isAvailable() async {
    final remaining = await remainingSlots();
    return remaining != null && remaining > 0;
  }
}
