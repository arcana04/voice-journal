import 'package:shared_preferences/shared_preferences.dart';

/// Notion連携の「接続済みかどうか」を端末に覚えておくためのローカル設定。
/// トークン自体はサーバー側(users/{uid}.notion、Cloud Functions経由でのみ
/// 読み書き)にしか保存せず、ここにはUI表示用のヒントだけを持つ。
class NotionSettingsService {
  static const _connectedPref = 'notion_connected';
  static const _pageTitlePref = 'notion_page_title';

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedPref) ?? false;
  }

  Future<String?> getPageTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pageTitlePref);
  }

  Future<void> setConnected(String? pageTitle) async {
    final prefs = await SharedPreferences.getInstance();
    if (pageTitle == null) {
      await prefs.remove(_connectedPref);
      await prefs.remove(_pageTitlePref);
    } else {
      await prefs.setBool(_connectedPref, true);
      await prefs.setString(_pageTitlePref, pageTitle);
    }
  }

  /// アカウント切り替え/アカウント削除で呼ぶ。[DbService.wipeAllLocalData]は
  /// SQLiteしか消さず、この「接続済みヒント」はSharedPreferencesに保存して
  /// いるため対象外だった——前のアカウントが接続していたNotionページの
  /// タイトルが、新しいアカウントの設定画面に「接続済み」としてそのまま
  /// 表示され続けてしまっていた（実際のトークンはサーバー側でuid別に
  /// 管理されているため送信自体は前のアカウントのページへは行かないが、
  /// 表示上は前のアカウント名義のページ名が漏れ、UIの状態も実態と食い違う）。
  Future<void> clear() => setConnected(null);
}
