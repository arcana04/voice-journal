import 'package:flutter/foundation.dart';

import '../services/apple_reminders_service.dart';
import '../services/apple_reminders_settings_service.dart';

/// 「リマインダー連携」設定画面と、選択中のリマインダーリストの状態を保持するストア。
class AppleRemindersStore extends ChangeNotifier {
  final AppleRemindersService _reminders = AppleRemindersService.instance;
  final AppleRemindersSettingsService _service =
      AppleRemindersSettingsService();

  String? selectedListId;
  String? selectedListName;
  bool _loaded = false;
  bool get loaded => _loaded;

  /// iOS以外（Androidには「リマインダー」に相当するOS標準アプリが無い）ではfalse。
  bool get isSupported => _reminders.isSupported;

  Future<void> load() async {
    selectedListId = await _service.getListId();
    selectedListName = await _service.getListName();
    _loaded = true;
    notifyListeners();
  }

  /// 権限をリクエストし、端末のリマインダーリスト一覧を取得する。
  /// 権限が得られなければ`granted: false`、得られたがリストが1件もなければ
  /// `granted: true`・空リストを返す。
  Future<({bool granted, List<({String id, String title})> lists})>
  requestLists() async {
    const empty = <({String id, String title})>[];
    if (!isSupported) return (granted: false, lists: empty);
    final granted = await _reminders.requestPermission();
    if (!granted) return (granted: false, lists: empty);
    final lists = await _reminders.fetchLists();
    return (granted: true, lists: lists);
  }

  Future<void> setList(({String id, String title})? list) async {
    selectedListId = list?.id;
    selectedListName = list?.title;
    await _service.setList(list?.id, list?.title);
    notifyListeners();
  }
}
