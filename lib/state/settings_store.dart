import 'package:flutter/material.dart';

import '../config/theme_colors.dart';
import '../models/summary_level.dart';
import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  SummaryLevel summaryLevel = SummaryLevel.preserve;
  bool darkMode = true;
  bool hasSeenOnboarding = false;
  bool aiConsentGiven = false;
  bool hasSeenNotificationHint = false;
  int accentColorIndex = 0;
  String? languageCode;
  int reminderOffsetMinutes = 0;
  bool autoNotificationsEnabled = true;
  int allDayReminderHour = 16;
  bool _loaded = false;
  bool get loaded => _loaded;

  /// nullは「端末の言語設定に従う」。[MaterialApp.locale]にそのまま渡す。
  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  /// アプリ全体のテーマカラー([kAccentColorPresets]から選んだもの)。設定画面の
  /// 「テーマカラー」で変更でき、[ColorScheme.fromSeed]のシードとしても
  /// 使われる(録音ボタン・波形など、あえて素のブランドカラーを使う数箇所も
  /// この値を参照する)。
  Color get accentColor =>
      kAccentColorPresets[accentColorIndex.clamp(
        0,
        kAccentColorPresets.length - 1,
      )];

  Future<void> load() async {
    summaryLevel = await _service.getSummaryLevel();
    darkMode = await _service.getDarkMode();
    hasSeenOnboarding = await _service.getHasSeenOnboarding();
    aiConsentGiven = await _service.getAiConsentGiven();
    // aiConsentGivenはこのセッションで新設したフラグ。同意ステップの導入
    // より前にオンボーディングを完了していた"本当に"既存のユーザーは、
    // フラグが無いだけで実際には（同意ステップが存在しなかった）旧版の
    // オンボーディングを経由済みのはずなので、ここで一度だけ補完する。
    //
    // ただし「hasSeenOnboarding == true」だけを根拠に無条件で補完していた
    // 以前の実装には抜けがあった: 同意ページ自体をスワイプ操作で迂回できる
    // バグ（onboarding_screen.dart参照、別途修正済み）と組み合わさると、
    // 「同意ステップがある今のフローを通ったが実際にはチェックしなかった」
    // ユーザーの false が、次回起動時にこの補完ロジックによって黙って
    // true に書き換えられてしまい、同意を得ていない事実が消えてしまって
    // いた。[_service.getOnboardingConsentStepSeen]（今のフロー＝同意
    // ページを含むフローを実際に通過したか）で両者を区別し、今のフロー
    // 経由のユーザーには決して補完しない——false は false のまま正直に
    // 残す。
    final onboardedWithConsentStep = await _service.getOnboardingConsentStepSeen();
    if (hasSeenOnboarding && !onboardedWithConsentStep && !aiConsentGiven) {
      aiConsentGiven = true;
      await _service.setAiConsentGiven(true);
    }
    hasSeenNotificationHint = await _service.getHasSeenNotificationHint();
    accentColorIndex = await _service.getAccentColorIndex();
    languageCode = await _service.getLanguageCode();
    reminderOffsetMinutes = await _service.getReminderOffsetMinutes();
    autoNotificationsEnabled = await _service.getAutoNotificationsEnabled();
    allDayReminderHour = await _service.getAllDayReminderHour();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setReminderOffsetMinutes(int value) async {
    reminderOffsetMinutes = value;
    await _service.setReminderOffsetMinutes(value);
    notifyListeners();
  }

  Future<void> setAutoNotificationsEnabled(bool value) async {
    autoNotificationsEnabled = value;
    await _service.setAutoNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setAllDayReminderHour(int value) async {
    allDayReminderHour = value;
    await _service.setAllDayReminderHour(value);
    notifyListeners();
  }

  Future<void> setAccentColorIndex(int index) async {
    accentColorIndex = index;
    await _service.setAccentColorIndex(index);
    notifyListeners();
  }

  /// nullを渡すと「端末の言語設定に従う」に戻る。
  Future<void> setLanguageCode(String? value) async {
    languageCode = value;
    await _service.setLanguageCode(value);
    notifyListeners();
  }

  /// [OnboardingScreen]の`onFinished`から呼ばれる。同スクリーンの_finish()は
  /// _aiConsentCheckedがtrueの場合にしか呼ばないため、ここに到達した時点で
  /// マイク許可+AI送信への同意は確実に得られている。同意ステップを含む今の
  /// フローを実際に完了した証として[setOnboardingConsentStepSeen]も併せて
  /// 記録する（[load]の互換バックフィル処理が、本当の既存ユーザーとの区別に
  /// 使う）。
  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    aiConsentGiven = true;
    await _service.setHasSeenOnboarding(true);
    await _service.setAiConsentGiven(true);
    await _service.setOnboardingConsentStepSeen(true);
    notifyListeners();
  }

  Future<void> setAiConsentGiven(bool value) async {
    aiConsentGiven = value;
    await _service.setAiConsentGiven(value);
    notifyListeners();
  }

  Future<void> dismissNotificationHint() async {
    if (hasSeenNotificationHint) return;
    hasSeenNotificationHint = true;
    await _service.setHasSeenNotificationHint(true);
    notifyListeners();
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    summaryLevel = value;
    await _service.setSummaryLevel(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _service.setDarkMode(value);
    notifyListeners();
  }
}
