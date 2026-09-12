import 'package:shared_preferences/shared_preferences.dart';

import '../models/summary_level.dart';

class SettingsService {
  static const _summaryLevelPref = 'summary_level';
  static const _darkModePref = 'dark_mode';
  static const _hasSeenOnboardingPref = 'has_seen_onboarding';
  static const _accentColorIndexPref = 'accent_color_index';
  static const _languageCodePref = 'language_code';
  static const _localDataOwnerUidPref = 'local_data_owner_uid';

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

  Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingPref) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingPref, value);
  }
}
