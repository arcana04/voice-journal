import 'package:flutter/material.dart';

/// アプリ全体のブランドカラー（インディゴ）の既定値。設定画面でテーマカラーを
/// 変更していない場合はこの値のまま（[SettingsStore.accentColor]参照）。
const Color kAppAccentColor = Color(0xFF6C5DD3);

/// 設定画面の「テーマカラー」で選べるプリセット。先頭が既定値(インディゴ)。
/// [ColorScheme.fromSeed]のシードにそのまま使えるよう、ある程度彩度のある
/// 色を選んでいる。
const List<Color> kAccentColorPresets = [
  kAppAccentColor, // インディゴ(既定)
  Color(0xFF2F6FE4), // ブルー
  Color(0xFF13A67D), // ティール
  Color(0xFFE84393), // ローズ
  Color(0xFFE2952F), // オレンジ
  Color(0xFFE0342B), // レッド
];
