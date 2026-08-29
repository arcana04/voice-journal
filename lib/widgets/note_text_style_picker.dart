import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/note_text_style.dart';

/// 日記の文字スタイル（サイズ・色・フォント）を選ぶ、見た目部分だけの部品。
/// 日記一覧画面の「お気に入り設定」シート（[TextStyleStore]のデフォルト値を
/// 変更）と、日記編集画面の「文字スタイル」シート（その場のdraftを変更）で
/// ほぼ同じビルダーコードが重複していたのをまとめたもの。選択状態の保存先は
/// コールバック経由で呼び出し側に任せる。
class NoteTextStylePicker extends StatelessWidget {
  static const _accent = Color(0xFF6C5DD3);

  /// フォントスタイルカードの背景に使う、順に巡回させるパステルカラー。
  static const _cardTints = [
    Color(0xFFEDE7FB),
    Color(0xFFFBF3DA),
    Color(0xFFE1EEFC),
    Color(0xFFFCE4EC),
    Color(0xFFE0F5EC),
    Color(0xFFFCEADD),
  ];

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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(color: _accent, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _sizeOption(String label, double scale) {
    final selected = fontScale == scale;
    return Expanded(
      child: GestureDetector(
        onTap: () => onFontScaleChanged(scale),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.12) : Colors.black
                .withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? _accent : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorOption(Color? color) {
    final selected = textColor == color;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => onTextColorChanged(color),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.transparent,
            border: Border.all(
              color: selected ? _accent : Colors.grey.withValues(alpha: 0.35),
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: color == null
              ? Icon(
                  Icons.block,
                  size: 18,
                  color: Colors.grey.withValues(alpha: 0.6),
                )
              : null,
        ),
      ),
    );
  }

  Widget _fontOption(BuildContext context, int index) {
    final option = noteFontOptions[index];
    final selected = fontFamilyIndex == index;
    final label = option.labelFor(AppLocalizations.of(context)!);
    final tint = _cardTints[index % _cardTints.length];
    return GestureDetector(
      onTap: () => onFontFamilyIndexChanged(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _accent : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: option.apply(
                const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.fontSheetSizeLabel),
        Row(
          children: [
            _sizeOption('H1', 1.5),
            _sizeOption('H2', 1.25),
            _sizeOption('H3', 1.0),
            _sizeOption('H4', 0.85),
          ],
        ),
        const SizedBox(height: 22),
        _sectionLabel(l10n.fontSheetColorLabel),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final color in noteTextColorOptions) _colorOption(color),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionLabel(l10n.fontSheetStyleLabel),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < noteFontOptions.length; i++)
              _fontOption(context, i),
          ],
        ),
      ],
    );
  }
}
