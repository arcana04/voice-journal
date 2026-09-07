import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ストア評価依頼を「ちょうど良い瞬間」だけに絞るためのゲート。OS側
/// (StoreKitのSKStoreReviewController／Play In-App Review)も年間の表示回数を
/// 自前で制限しているが、こちらでも直近で依頼済みなら間隔を空け、
/// エラー直後などネガティブな文脈では絶対に呼ばないようにする。
class ReviewPromptService {
  static const _lastShownPref = 'review_prompt_last_shown_epoch_ms';

  /// この日数だけ経てば再度依頼して良い。OS側の年間上限とは別に、
  /// こちらからは無闇に呼ばないための自主的な間隔。_milestones同士の最短間隔
  /// (3日→14日の11日)より短くして、どの節目も潰されずに機会を持てるようにする。
  static const _minGapDays = 7;

  /// 依頼して良いと判断するstreak(連続記録日数)の節目。「今ちょうど記録を
  /// 続けられて嬉しい」瞬間に限定するため、キリの良い日数だけを対象にする。
  static const Set<int> _milestones = {3, 14, 60};

  final InAppReview _inAppReview;

  ReviewPromptService({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  /// 録音の保存が成功した直後など、ユーザーが満足しているはずの瞬間に呼ぶ。
  /// 節目のstreakでなければ何もしない。
  Future<void> maybeRequestForStreak(int streakDays) async {
    if (!_milestones.contains(streakDays)) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShownMs = prefs.getInt(_lastShownPref);
    if (lastShownMs != null) {
      final since = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastShownMs),
      );
      if (since.inDays < _minGapDays) return;
    }

    if (!await _inAppReview.isAvailable()) return;
    await _inAppReview.requestReview();
    await prefs.setInt(_lastShownPref, DateTime.now().millisecondsSinceEpoch);
  }
}
