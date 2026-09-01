import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/emotion_tag.dart';

/// その日1日の感情が記録されていない曜日の色（参考デザインの背景トーンに
/// 馴染む、控えめな暗いスレート色）。
const Color _kAuroraEmptyColor = Color(0xFF2A3040);

/// 参考デザインの泡の背景と同じ濃紺（実測値: rgb(4,12,31)）。
const Color _kAuroraBackdrop = Color(0xFF040C1F);

/// その日1日に記録された感情（複数あり得る）を、件数で重み付けして1色に
/// ブレンドする。単純なRGB平均だと彩度の高い色同士が濁った灰色になりやすい
/// ため、色相は円環平均（wrap-around考慮）、彩度・明度は加重平均する。
Color blendDayEmotionColors(Map<EmotionTag, int> counts) {
  if (counts.isEmpty) return _kAuroraEmptyColor;

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

  if (totalWeight == 0) return _kAuroraEmptyColor;

  var hue = math.atan2(sinSum, cosSum) * 180 / math.pi;
  if (hue < 0) hue += 360;
  final saturation = (satSum / totalWeight).clamp(0.0, 1.0);
  final lightness = (lightSum / totalWeight).clamp(0.0, 1.0);
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

/// 週刊脳内レポートの「今週のオーロラ」。7日分の感情ブレンド色を横方向に
/// 滑らかなグラデーションで繋ぎ、波打つ半透明の帯を重ねてオーロラらしい
/// 揺らぎを表現する。
class WeeklyAurora extends StatelessWidget {
  /// 月曜始まり7件。各要素はその日に記録された感情タグごとの件数。
  final List<Map<EmotionTag, int>> dailyEmotionCounts;
  final DateTime weekStart;
  final String locale;

  const WeeklyAurora({
    super.key,
    required this.dailyEmotionCounts,
    required this.weekStart,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final dayColors = dailyEmotionCounts.map(blendDayEmotionColors).toList();
    final dayZero = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: CustomPaint(
          painter: _WeeklyAuroraPainter(dayColors: dayColors),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Text(
                    DateFormat.E(locale).format(dayZero.add(Duration(days: i))),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuroraBand {
  final double baseY;
  final double amplitude;
  final double freq;
  final double phase;
  final double thickness;
  final double opacity;

  const _AuroraBand({
    required this.baseY,
    required this.amplitude,
    required this.freq,
    required this.phase,
    required this.thickness,
    required this.opacity,
  });
}

class _WeeklyAuroraPainter extends CustomPainter {
  final List<Color> dayColors;

  _WeeklyAuroraPainter({required this.dayColors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = _kAuroraBackdrop,
    );

    if (dayColors.isEmpty) return;

    final stops = dayColors.length == 1
        ? <double>[0, 1]
        : List<double>.generate(dayColors.length, (i) => i / (dayColors.length - 1));
    final gradientColors = dayColors.length == 1 ? [dayColors.first, dayColors.first] : dayColors;

    // 振幅・太さはキャンバスの縦幅に比例させ、高さを変えても揺らぎの
    // スケール感が保たれるようにする。
    final h = size.height;
    final bands = [
      _AuroraBand(
        baseY: h * 0.30,
        amplitude: h * 0.10,
        freq: 1.6,
        phase: 0.0,
        thickness: h * 0.20,
        opacity: 0.5,
      ),
      _AuroraBand(
        baseY: h * 0.50,
        amplitude: h * 0.14,
        freq: 1.1,
        phase: 1.4,
        thickness: h * 0.26,
        opacity: 0.42,
      ),
      _AuroraBand(
        baseY: h * 0.70,
        amplitude: h * 0.11,
        freq: 2.0,
        phase: 2.6,
        thickness: h * 0.18,
        opacity: 0.38,
      ),
    ];

    for (final band in bands) {
      final path = Path();
      const step = 6.0;
      for (var x = 0.0; x <= size.width; x += step) {
        final t = size.width == 0 ? 0.0 : x / size.width;
        final y = band.baseY +
            band.amplitude * math.sin(t * band.freq * 2 * math.pi + band.phase) +
            (band.amplitude * 0.5) *
                math.sin(t * band.freq * 4.3 * math.pi + band.phase * 1.7);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // 外側のソフトなグロー（滲み）。ぼかしは控えめにして、揺らぎの
      // 輪郭がちゃんと見える「帯」として認識できるようにする。
      final glowColors = gradientColors.map((c) => c.withValues(alpha: band.opacity)).toList();
      final glowShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: glowColors,
        stops: stops,
      ).createShader(rect);
      canvas.drawPath(
        path,
        Paint()
          ..shader = glowShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = band.thickness
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..blendMode = BlendMode.plus,
      );

      // 内側の明るい芯。ここをシャープに保つことで、単なるぼやけた光では
      // なく「光の帯が流れている」ように見せる。
      final coreColors =
          gradientColors.map((c) => c.withValues(alpha: (band.opacity + 0.35).clamp(0.0, 1.0))).toList();
      final coreShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: coreColors,
        stops: stops,
      ).createShader(rect);
      canvas.drawPath(
        path,
        Paint()
          ..shader = coreShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = band.thickness * 0.32
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
          ..blendMode = BlendMode.plus,
      );
    }

    // カーテンのように縦に伸びる光の筋を薄く重ね、単なる横帯ではなく
    // 「垂れ下がるオーロラ」らしい質感を足す。
    final rng = math.Random(7);
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * size.width;
      final dayIndex = gradientColors.length == 1
          ? 0
          : (x / size.width * (gradientColors.length - 1)).round().clamp(0, gradientColors.length - 1);
      final rayColor = gradientColors[dayIndex];
      final rayHeight = h * (0.35 + rng.nextDouble() * 0.4);
      final rayTop = rng.nextDouble() * (h - rayHeight);
      canvas.drawRect(
        Rect.fromLTWH(x, rayTop, 1.6, rayHeight),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rayColor.withValues(alpha: 0),
              rayColor.withValues(alpha: 0.16 + rng.nextDouble() * 0.1),
              rayColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x, rayTop, 1.6, rayHeight))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyAuroraPainter oldDelegate) {
    return oldDelegate.dayColors != dayColors;
  }
}
