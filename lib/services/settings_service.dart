import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/summary_level.dart';

class SettingsService {
  static const _summaryLevelPref = 'summary_level';
  static const _darkModePref = 'dark_mode';
  static const _hasSeenOnboardingPref = 'has_seen_onboarding';
  static const _aiConsentGivenPref = 'ai_consent_given';
  static const _trialEndsAtPref = 'trial_ends_at';
  static const _hasSeenNotificationHintPref = 'has_seen_notification_hint';
  static const _accentColorIndexPref = 'accent_color_index';
  static const _languageCodePref = 'language_code';
  static const _localDataOwnerUidPref = 'local_data_owner_uid';
  static const _reminderOffsetMinutesPref = 'reminder_offset_minutes';
  static const _autoNotificationsEnabledPref = 'auto_notifications_enabled';
  static const _allDayReminderHourPref = 'all_day_reminder_hour';

  /// 端末ローカルのSQLiteデータが最後にどのアカウント(Firebase uid)のもので
  /// あったかを記録する。サインアウトはローカルデータを消さない設計のため、
  /// 同じ端末で別の既存アカウントに切り替えると、前のアカウントのデータが
  /// 残ったまま新アカウントの「クラウドから復元」で誤って新アカウント側に
  /// 送信されてしまう恐れがある
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。AccountStoreが
  /// サインイン成功時にこの値と食い違っていないか確認するために使う。
  Future<String?> getLocalDataOwnerUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localDataOwnerUidPref);
  }

  Future<void> setLocalDataOwnerUid(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null) {
      await prefs.remove(_localDataOwnerUidPref);
    } else {
      await prefs.setString(_localDataOwnerUidPref, uid);
    }
  }

  /// クラウドへの書き込み（[CloudSyncService.pushEntry]/[MediaSyncService]の
  /// アップロード系）が呼ばれる直前の最終防衛ライン。`signInWithCredential`は
  /// `FirebaseAuth.instance.currentUser`を即座に新アカウントへ切り替えるが、
  /// [AccountStore._guardAccountSwitch]によるローカルデータの消去（＝
  /// [setLocalDataOwnerUid]の更新）はその後に非同期で完了するため、ごく短い
  /// 間だけ「currentUserは新アカウントなのに、ローカルデータはまだ前の
  /// アカウントのもの」という状態が存在しうる。この間に何かがクラウド書き込みを
  /// 起こすと、前アカウントのデータが新アカウントのFirestore/Storageへ紛れ込む
  /// （現状そのような呼び出し経路は無いが、将来の機能追加で再発しうる潜在リスク）。
  /// 記録が無い（この端末で初めての紐付け）場合は、通常の初回同期を妨げない
  /// よう素通り（true）する。
  Future<bool> currentUserOwnsLocalData() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return false;
    final ownerUid = await getLocalDataOwnerUid();
    if (ownerUid == null) return true;
    return ownerUid == currentUid;
  }

  Future<SummaryLevel> getSummaryLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return SummaryLevelX.fromWireValue(prefs.getString(_summaryLevelPref));
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLevelPref, value.wireValue);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModePref) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModePref, value);
  }

  Future<int> getAccentColorIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_accentColorIndexPref) ?? 0;
  }

  Future<void> setAccentColorIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorIndexPref, index);
  }

  /// nullは「端末の言語設定に従う」を意味する。
  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodePref);
  }

  Future<void> setLanguageCode(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_languageCodePref);
    } else {
      await prefs.setString(_languageCodePref, value);
    }
  }

  /// タスクの通知を、開始時刻の何分前に飛ばすかの既定値（0なら開始時刻
  /// ちょうど）。AIが音声からタスクを作った直後の通知時刻の既定値として使う
  /// （個々のタスクは後からTaskEditScreenで独立に変更できる）。
  Future<int> getReminderOffsetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderOffsetMinutesPref) ?? 0;
  }

  Future<void> setReminderOffsetMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderOffsetMinutesPref, value);
  }

  /// falseなら、AIがタスクを作った時点では通知を一切設定しない（カレンダー/
  /// リマインダーアプリへの反映だけしたいユーザー向け）。個々のタスクは
  /// 後からTaskEditScreenで手動で通知を付けられる。
  Future<bool> getAutoNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoNotificationsEnabledPref) ?? true;
  }

  Future<void> setAutoNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoNotificationsEnabledPref, value);
  }

  /// 終日タスクの既定通知時刻（期限日の前日、この時（0〜23）に通知する）。
  Future<int> getAllDayReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_allDayReminderHourPref) ?? 16;
  }

  Future<void> setAllDayReminderHour(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_allDayReminderHourPref, value);
  }

  Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingPref) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingPref, value);
  }

  /// マイク許可+OpenAIへのデータ送信への明示同意（App Store審査ガイドライン
  /// 5.1.1(i)/5.1.2(i)対応）。以前はオンボーディング画面内のローカル変数
  /// （チェックボックスの状態）のみで管理しており、どこにも永続化されておらず、
  /// 実質的にUI上の見せかけのゲートに留まっていた（オンボーディングの
  /// 「スキップ」ボタンが同意ページ自体を迂回できるバグと合わせて発覚）。
  Future<bool> getAiConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiConsentGivenPref) ?? false;
  }

  Future<void> setAiConsentGiven(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiConsentGivenPref, value);
  }

  /// レビュー画面で「時刻付きタスクには自動で通知が設定される」ことを示す
  /// 一度きりのヒントバナーを、既に見せたかどうか。時刻を録音しただけで
  /// 通知が裏側で自動設定される挙動は画面上に説明が一切無く、ユーザーが
  /// 気づかないまま届く通知に戸惑う可能性があったため追加した
  /// （一度閉じたら二度と表示しない）。
  Future<bool> getHasSeenNotificationHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenNotificationHintPref) ?? false;
  }

  Future<void> setHasSeenNotificationHint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenNotificationHintPref, value);
  }

  /// トライアル終了3日前通知([ReminderService.scheduleTrialEndingNotification])
  /// の対象時刻を永続化する。AndroidのAlarmManagerベースのローカル通知は端末
  /// 再起動で消えるため、以前はこの通知だけ再起動後に復元する手段が無く
  /// （タスクリマインダーは[ReminderService.rescheduleAllPending]がDBから
  /// 読み直して復元するが、トライアル終了通知はどこにも保存されていなかった）、
  /// 再起動を挟むとユーザーが気づかないままトライアルが終了し課金される
  /// リスクがあった。
  Future<DateTime?> getTrialEndsAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_trialEndsAtPref);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> setTrialEndsAt(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_trialEndsAtPref);
    } else {
      await prefs.setString(_trialEndsAtPref, value.toIso8601String());
    }
  }
}
