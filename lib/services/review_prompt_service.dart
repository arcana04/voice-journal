import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ストア評価依頼を「ちょうど良い瞬間」だけに絞るためのゲート。OS側
/// (StoreKitのSKStoreReviewController／Play In-App Review)も年間の表示回数を
/// 自前で制限しているが、こちらでも直近で依頼済みなら間隔を空け、
/// エラー直後などネガティブな文脈では絶対に呼ばないようにする。
class ReviewPromptService {
  static const _lastShownPref = 'review_prompt_last_shown_epoch_ms';
  static const _hasSeenUnlockedWeeklyReportPref =
      'review_prompt_has_seen_unlocked_weekly_report';
  static const _hasCompletedFirstAiTaskPref =
      'review_prompt_has_completed_first_ai_task';

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
    await _maybeShow();
  }

  /// 日曜20時解禁後の週刊脳内レポートを初めて見た直後に呼ぶ。履歴(過去の
  /// 確定済みレポート)の閲覧は対象外——「今まさに解禁された」という驚きが
  /// ある瞬間に限定するため。一度きりのトリガーなので内部で既読フラグを
  /// 管理する。
  Future<void> maybeRequestForFirstUnlockedWeeklyReport() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasSeenUnlockedWeeklyReportPref) ?? false) return;
    await prefs.setBool(_hasSeenUnlockedWeeklyReportPref, true);
    await _maybeShow();
  }

  /// AIが音声/テキストから自動生成したタスクを、ユーザーが初めて完了
  /// (チェックオフ)した直後に呼ぶ。「AIに任せたら実際に生活が回った」という
  /// 成功体験の瞬間。手動作成タスクの完了では呼ばない。
  Future<void> maybeRequestForFirstAiTaskCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasCompletedFirstAiTaskPref) ?? false) return;
    await prefs.setBool(_hasCompletedFirstAiTaskPref, true);
    await _maybeShow();
  }

  Future<void> _maybeShow() async {
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
