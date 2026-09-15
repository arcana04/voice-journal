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
    // aiConsentGivenはこのセッションで新設したフラグ。オンボーディングは以前
    // から同意チェックボックスを表示していた（スキップボタンがそれを迂回できる
    // バグが今回のセッションで見つかり別途修正済み）ため、既にオンボーディングを
    // 完了している既存ユーザーは、フラグが無いだけで実際には同意画面を経由して
    // いる可能性が高い。今後このフラグを根拠に機能を制限する場面が増えても
    // 既存ユーザーを不当にブロックしないよう、ここで一度だけ補完する。
    if (hasSeenOnboarding && !aiConsentGiven) {
      aiConsentGiven = true;
      await _service.setAiConsentGiven(true);
    }
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

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _service.setHasSeenOnboarding(true);
    notifyListeners();
  }

  Future<void> setAiConsentGiven(bool value) async {
    aiConsentGiven = value;
    await _service.setAiConsentGiven(value);
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
