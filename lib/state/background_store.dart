import 'package:flutter/material.dart';

import '../models/app_background.dart';
import '../services/background_settings_service.dart';

/// アプリ全体（録音・日記・アイデア・タスク）で共通に使う背景画像の選択状態。
/// [selected]がnullの場合は「デフォルト」＝各画面固有の背景画像を使う。
class BackgroundStore extends ChangeNotifier {
  final BackgroundSettingsService _service = BackgroundSettingsService();

  AppBackground? selected;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    selected = AppBackground.fromId(await _service.getBackgroundId());
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBackground(AppBackground? background) async {
    selected = background;
    await _service.setBackgroundId(background?.id);
    notifyListeners();
  }
}
