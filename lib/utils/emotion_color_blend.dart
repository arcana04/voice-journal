import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/emotion_tag.dart';

/// 感情の記録が無い場合のフォールバック色(控えめな暗いスレート色)。
/// 「今週のオーロラ」の記録の無い曜日、「脳内マップ」の感情タグが
/// 紐づかなかったキーワードなど、複数箇所で共通して使うニュートラル色。
const Color kEmotionBlendEmptyColor = Color(0xFF2A3040);

/// 複数の感情(件数で重み付け)を1色にブレンドする。単純なRGB平均だと彩度の
/// 高い色同士が濁った灰色になりやすいため、色相は円環平均(wrap-around考慮)、
/// 彩度・明度は加重平均する。「今週のオーロラ」(1日分の感情)と「脳内マップ」
/// (1キーワードに紐づく感情)の両方で共通して使う。
Color blendEmotionColors(Map<EmotionTag, int> counts) {
  if (counts.isEmpty) return kEmotionBlendEmptyColor;

  var sinSum = 0.0;
  var cosSum = 0.0;
  var satSum = 0.0;
  var lightSum = 0.0;
  var totalWeight = 0;

  for (final entry in counts.entries) {
    final hsl = HSLColor.fromColor(entry.key.color);
    final weight = entry.value;
    if (weight <= 0) continue;
    final hueRad = hsl.hue * math.pi / 180;
    sinSum += math.sin(hueRad) * weight;
    cosSum += math.cos(hueRad) * weight;
    satSum += hsl.saturation * weight;
    lightSum += hsl.lightness * weight;
    totalWeight += weight;
  }

  if (totalWeight == 0) return kEmotionBlendEmptyColor;

  var hue = math.atan2(sinSum, cosSum) * 180 / math.pi;
  if (hue < 0) hue += 360;
  final saturation = (satSum / totalWeight).clamp(0.0, 1.0);
  final lightness = (lightSum / totalWeight).clamp(0.0, 1.0);
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}
