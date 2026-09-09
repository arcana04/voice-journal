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
}
