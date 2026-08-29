import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/note_text_style.dart';

/// 日記の文字スタイル（サイズ・色・フォント）を選ぶ、見た目部分だけの部品。
/// 日記一覧画面の「お気に入り設定」シート（[TextStyleStore]のデフォルト値を
/// 変更）と、日記編集画面の「文字スタイル」シート（その場のdraftを変更）で
/// ほぼ同じビルダーコードが重複していたのをまとめたもの。選択状態の保存先は
/// コールバック経由で呼び出し側に任せる。
class NoteTextStylePicker extends StatelessWidget {
  final int fontFamilyIndex;
  final Color? textColor;
  final double fontScale;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<Color?> onTextColorChanged;
  final ValueChanged<int> onFontFamilyIndexChanged;

  const NoteTextStylePicker({
    super.key,
    required this.fontFamilyIndex,
    required this.textColor,
    required this.fontScale,
    required this.onFontScaleChanged,
    required this.onTextColorChanged,
    required this.onFontFamilyIndexChanged,
  });

  Widget _sizeOption(String label, double scale) {
    final selected = fontScale == scale;
    return Expanded(
      child: GestureDetector(
        onTap: () => onFontScaleChanged(scale),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blue.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorOption(Color? color) {
    final selected = textColor == color;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => onTextColorChanged(color),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.transparent,
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: color == null
              ? Icon(Icons.block, size: 18, color: Colors.grey.withValues(alpha: 0.6))
              : null,
        ),
      ),
    );
  }

  Widget _fontOption(BuildContext context, int index) {
    final option = noteFontOptions[index];
    final selected = fontFamilyIndex == index;
    final label = option.labelFor(AppLocalizations.of(context)!);
    return GestureDetector(
      onTap: () => onFontFamilyIndexChanged(index),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: option.apply(const TextStyle(fontSize: 15))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sizeOption('H1', 1.5),
            _sizeOption('H2', 1.25),
            _sizeOption('H3', 1.0),
            _sizeOption('H4', 0.85),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (final color in noteTextColorOptions) _colorOption(color)],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (var i = 0; i < noteFontOptions.length; i++) _fontOption(context, i),
          ],
        ),
      ],
    );
  }
}
