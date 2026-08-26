import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/text_style_store.dart';

class NoteFontOption {
  final String Function(AppLocalizations l10n) labelFor;
  final TextStyle Function(TextStyle base) apply;
  const NoteFontOption(this.labelFor, this.apply);
}

/// 日記本文に選べるフォントの一覧。インデックスは[NoteItem.fontFamilyIndex]や
/// [TextStyleStore.fontFamilyIndex]として保存される値と対応する。
final List<NoteFontOption> noteFontOptions = [
  NoteFontOption((l10n) => l10n.fontStandard, (base) => base),
  NoteFontOption(
    (l10n) => l10n.fontMincho,
    (base) => GoogleFonts.shipporiMincho(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontHandwriting,
    (base) => GoogleFonts.kleeOne(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontPop,
    (base) => GoogleFonts.hachiMaruPop(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontMonospace,
    (base) => GoogleFonts.mPlus1Code(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontGothic,
    (base) => GoogleFonts.zenKakuGothicNew(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontRoundGothic,
    (base) => GoogleFonts.mPlusRounded1c(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontThinMincho,
    (base) => GoogleFonts.hinaMincho(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontBrush,
    (base) => GoogleFonts.yujiSyuku(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontRetro,
    (base) => GoogleFonts.dotGothic16(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontImpact,
    (base) => GoogleFonts.delaGothicOne(textStyle: base),
  ),
  NoteFontOption(
    (l10n) => l10n.fontCute,
    (base) => GoogleFonts.yuseiMagic(textStyle: base),
  ),
];

const List<Color?> noteTextColorOptions = [
  null,
  Colors.black87,
  Color(0xFF6B6B6B),
  Colors.redAccent,
  Colors.deepOrange,
  Color(0xFFB8860B),
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.purple,
  Colors.pink,
];

/// [note]に保存済みのスタイルがあればそれを、無ければアプリ全体のデフォルト
/// ([defaults])を使って、[base]にフォント・色・サイズ倍率を適用する。
TextStyle? applyNoteStyle(
  TextStyle? base, {
  required NoteItem note,
  required TextStyleStore defaults,
}) {
  if (base == null) return null;
  final fontFamilyIndex = note.fontFamilyIndex ?? defaults.fontFamilyIndex;
  final textColor = note.fontFamilyIndex != null
      ? (note.textColorValue != null ? Color(note.textColorValue!) : null)
      : defaults.textColor;
  final fontScale = note.fontScale ?? defaults.fontScale;

  final scaled = base.copyWith(
    fontSize: (base.fontSize ?? 16) * fontScale,
    color: textColor ?? base.color,
  );
  final index = fontFamilyIndex >= 0 && fontFamilyIndex < noteFontOptions.length
      ? fontFamilyIndex
      : 0;
  return noteFontOptions[index].apply(scaled);
}
