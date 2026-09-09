import 'package:flutter/foundation.dart';

import '../models/notion_page.dart';
import '../services/backend_service.dart';
import '../services/notion_settings_service.dart';

/// Notion連携(1タップ送信)の設定画面と、接続状態を保持するストア。
/// トークン自体はサーバー側(users/{uid}.notion)にしか保存しない
/// ([NotionSettingsService]はUI表示用の「接続済みか」のヒントのみ)。
class NotionStore extends ChangeNotifier {
  final BackendService _backend = BackendService();
  final NotionSettingsService _service = NotionSettingsService();

  bool isConnected = false;
  String? connectedPageTitle;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    isConnected = await _service.isConnected();
    connectedPageTitle = await _service.getPageTitle();
    _loaded = true;
    notifyListeners();
  }

  /// トークンを検証し、共有済みページの一覧を返す(まだ何も保存しない)。
  Future<List<NotionPage>> connect(String token, {required String locale}) {
    return _backend.notionListPages(token, locale: locale);
  }

  /// 選ばれたページ配下にデータベースを作成し、接続済み状態を保存する。
  Future<void> finishSetup(
    String token,
    NotionPage page, {
    required String locale,
  }) async {
    await _backend.notionSetupDatabase(token, page.id, locale: locale);
    isConnected = true;
    connectedPageTitle = page.title;
    await _service.setConnected(page.title);
    notifyListeners();
  }

  Future<void> disconnect({required String locale}) async {
    await _backend.notionDisconnect(locale: locale);
    isConnected = false;
    connectedPageTitle = null;
    await _service.setConnected(null);
    notifyListeners();
  }
}
