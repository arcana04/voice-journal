import 'package:flutter/material.dart';

import '../services/text_style_settings_service.dart';

/// 日記編集画面の文字スタイル（フォント・色・サイズ）のデフォルト設定。
/// ユーザーが「デフォルトに設定」した内容を保持し、以後の編集画面はここから初期値を読む。
class TextStyleStore extends ChangeNotifier {
  final TextStyleSettingsService _service = TextStyleSettingsService();

  int fontFamilyIndex = 0;
  Color? textColor;
  double fontScale = 1.0;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    fontFamilyIndex = await _service.getFontFamilyIndex();
    textColor = await _service.getTextColor();
    fontScale = await _service.getFontScale();
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
}
