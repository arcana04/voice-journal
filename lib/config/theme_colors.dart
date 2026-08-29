import 'package:flutter/material.dart';

/// アプリ全体のブランドカラー（インディゴ）。[ColorScheme.fromSeed]のシードにも
/// 使う唯一のソース（[VoiceJournalApp]参照）。
const Color kAppAccentColor = Color(0xFF6C5DD3);

/// 録音ボタン・波形アニメーションに使う色。Material3のシードカラーから自動生成
/// される`colorScheme.primary`はトーンがやや落ち着くため、この2箇所だけは
/// ブランドカラーそのもの（[kAppAccentColor]）を明示的に使う。
const Color kRecordAccentColor = kAppAccentColor;
