import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/emotion_tag.dart';
import '../utils/emotion_color_blend.dart';

/// 参考デザインの泡の背景と同じ濃紺(実測値: rgb(4,12,31))。
const Color _kAuroraBackdrop = Color(0xFF040C1F);

/// 週刊脳内レポートの「今週のオーロラ」。7日分の感情ブレンド色を横方向に
/// つなぎ、参考写真(無数の光の筋が波打つ根元から立ち上るカーテン状の
/// オーロラ)の構図を色付きで再現する。
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
    final dayColors = dailyEmotionCounts.map(blendEmotionColors).toList();
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

class _WeeklyAuroraPainter extends CustomPainter {
  final List<Color> dayColors;

  _WeeklyAuroraPainter({required this.dayColors});

  /// オーロラの根元(最も明るい帯)の高さ。参考写真はほぼ平らな稜線に
  /// うっすら1つの起伏があるだけなので、低周波のsin1つに留める(高周波を
  /// 混ぜると輪郭がはっきりした瘤の連続に見えてしまう)。
  double _ridgeY(double t, double h) {
    return h * 0.5 + h * 0.05 * math.sin(t * 2 * math.pi + 0.6);
  }

  Color _colorAt(List<Color> colors, double t) {
    if (colors.length == 1) return colors[0];
    final scaled = t.clamp(0.0, 1.0) * (colors.length - 1);
    final i0 = scaled.floor().clamp(0, colors.length - 1);
    final i1 = (i0 + 1).clamp(0, colors.length - 1);
    return Color.lerp(colors[i0], colors[i1], scaled - i0) ?? colors[i0];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = _kAuroraBackdrop,
    );

    if (dayColors.isEmpty) return;

    final gradientColors = dayColors.length == 1 ? [dayColors.first, dayColors.first] : dayColors;
    final stops = gradientColors.length == 1
        ? <double>[0, 1]
        : List<double>.generate(gradientColors.length, (i) => i / (gradientColors.length - 1));

    final h = size.height;
    final w = size.width;

    // 星: 参考写真のように、暗い上空にうっすら瞬く点を散らす。
    final starRng = math.Random(3);
    for (var i = 0; i < 55; i++) {
      final x = starRng.nextDouble() * w;
      final y = starRng.nextDouble() * h * 0.55;
      final r = 0.5 + starRng.nextDouble() * 0.9;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.12 + starRng.nextDouble() * 0.25),
      );
    }

    // 根元をなだらかに繋ぐ、稜線に沿った下地のグロー。輪郭が見えないよう
    // 強めのぼかしを何層も重ね、あくまで「もや」として広がらせる。
    final ridgePath = Path();
    const step = 6.0;
    for (var x = 0.0; x <= w; x += step) {
      final t = w == 0 ? 0.0 : x / w;
      final y = _ridgeY(t, h);
      if (x == 0) {
        ridgePath.moveTo(x, y);
      } else {
        ridgePath.lineTo(x, y);
      }
    }
    void drawRidgeHaze(double widthFactor, double alpha, double blurSigma) {
      final shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: gradientColors.map((c) => c.withValues(alpha: alpha)).toList(),
        stops: stops,
      ).createShader(rect);
      canvas.drawPath(
        ridgePath,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * widthFactor
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
          ..blendMode = BlendMode.plus,
      );
    }

    drawRidgeHaze(0.95, 0.28, 34);
    drawRidgeHaze(0.55, 0.34, 22);
    drawRidgeHaze(0.26, 0.4, 12);

    // 無数の縦の光の筋。根元から立ち上る高さ・太さをランダムにばらつかせ
    // つつ、強めにぼかして輪郭のはっきりした線ではなく「もや」として
    // 溶け合わせる。
    final rayRng = math.Random(11);
    final rayCount = (w / 2.6).clamp(80, 260).round();
    for (var i = 0; i < rayCount; i++) {
      final x = rayRng.nextDouble() * w;
      final t = w == 0 ? 0.0 : x / w;
      final baseY = _ridgeY(t, h);
      final color = _colorAt(gradientColors, t);

      final tall = rayRng.nextDouble() < 0.12;
      final rayHeight =
          tall ? h * (0.5 + rayRng.nextDouble() * 0.4) : h * (0.15 + rayRng.nextDouble() * 0.3);
      final dropBelow = h * 0.08;
      final topY = baseY - rayHeight;
      final bottomY = baseY + dropBelow;
      final rayWidth = tall ? 3.0 + rayRng.nextDouble() * 2.0 : 2.0 + rayRng.nextDouble() * 2.4;
      final peakAlpha = tall ? 0.22 + rayRng.nextDouble() * 0.12 : 0.10 + rayRng.nextDouble() * 0.14;

      final rayRect = Rect.fromLTWH(x, topY, rayWidth, bottomY - topY);
      canvas.drawRect(
        rayRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: peakAlpha),
              color.withValues(alpha: peakAlpha * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 0.78, 1.0],
          ).createShader(rayRect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, tall ? 7.0 : 5.0)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyAuroraPainter oldDelegate) {
    return oldDelegate.dayColors != dayColors;
  }
}
