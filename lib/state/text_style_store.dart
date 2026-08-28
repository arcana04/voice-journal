import 'package:flutter/material.dart';

import '../services/text_style_settings_service.dart';

/// 日記の「お気に入り設定」（文字スタイルと背景画像）のデフォルト値。
/// ユーザーが「デフォルトに設定」した内容を保持し、新規日記や未設定の既存日記は
/// ここから初期値を読む（[[project_voicejournal_status]]参照）。
class TextStyleStore extends ChangeNotifier {
  final TextStyleSettingsService _service = TextStyleSettingsService();

  int fontFamilyIndex = 0;
  Color? textColor;
  double fontScale = 1.0;
  String? backgroundId;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    fontFamilyIndex = await _service.getFontFamilyIndex();
    textColor = await _service.getTextColor();
    fontScale = await _service.getFontScale();
    backgroundId = await _service.getBackgroundId();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDefault({
    required int fontFamilyIndex,
    required Color? textColor,
    required double fontScale,
  }) async {
    this.fontFamilyIndex = fontFamilyIndex;
    this.textColor = textColor;
    this.fontScale = fontScale;
    await _service.setDefault(
      fontFamilyIndex: fontFamilyIndex,
      textColor: textColor,
      fontScale: fontScale,
    );
    notifyListeners();
  }

  Future<void> setDefaultBackground(String? backgroundId) async {
    this.backgroundId = backgroundId;
    await _service.setBackgroundId(backgroundId);
    notifyListeners();
  }
}
