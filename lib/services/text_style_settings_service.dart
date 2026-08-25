import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextStyleSettingsService {
  static const _fontFamilyIndexPref = 'text_style_font_family_index';
  static const _textColorPref = 'text_style_text_color';
  static const _fontScalePref = 'text_style_font_scale';

  Future<int> getFontFamilyIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_fontFamilyIndexPref) ?? 0;
  }

  Future<Color?> getTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    final argb = prefs.getInt(_textColorPref);
    return argb == null ? null : Color(argb);
  }

  Future<double> getFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontScalePref) ?? 1.0;
  }

  Future<void> setDefault({
    required int fontFamilyIndex,
    required Color? textColor,
    required double fontScale,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyIndexPref, fontFamilyIndex);
    await prefs.setDouble(_fontScalePref, fontScale);
    if (textColor == null) {
      await prefs.remove(_textColorPref);
    } else {
      await prefs.setInt(_textColorPref, textColor.toARGB32());
    }
  }
}
