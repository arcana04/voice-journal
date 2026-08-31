import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/emotion_tag.dart';

/// その日1日の感情のうち、ポジティブ／ネガティブがそれぞれ何割を占めるか
/// （0〜1）。記録が無い日はどちらもnull（後で滑らかに補間する）。
class DayMoodFractions {
  final double? positive;
  final double? negative;

  const DayMoodFractions({required this.positive, required this.negative});
}

DayMoodFractions dayMoodFractions(Map<EmotionTag, int> counts) {
  if (counts.isEmpty) {
    return const DayMoodFractions(positive: null, negative: null);
  }
  var positive = 0;
  var negative = 0;
  var total = 0;
  for (final entry in counts.entries) {
    total += entry.value;
    switch (entry.key.category) {
      case EmotionCategory.positive:
        positive += entry.value;
      case EmotionCategory.negative:
        negative += entry.value;
      case EmotionCategory.fine:
        break;
    }
  }
  if (total == 0) return const DayMoodFractions(positive: null, negative: null);
  return DayMoodFractions(positive: positive / total, negative: negative / total);
}

/// 週刊脳内レポートの「メンタルウェーブ」。ポジティブ（オレンジ）とネガティブ
/// （パープル）、独立した2本の波線を中央の基準線から上下に描く。つぶやきが
/// 無い日は前後の記録から自然に滑らかに補間する。
class MentalWaveChart extends StatelessWidget {
  /// 月曜始まり7件。各要素はその日に記録された感情タグごとの件数。
  final List<Map<EmotionTag, int>> dailyEmotionCounts;
  final DateTime weekStart;
  final String locale;

  const MentalWaveChart({
    super.key,
    required this.dailyEmotionCounts,
    required this.weekStart,
    required this.locale,
  });

  static const Color _backdrop = Color(0xFF10162B);
  static const Color positiveColor = Color(0xFFF2A93B);
  static const Color negativeColor = Color(0xFF8B90F0);

  @override
  Widget build(BuildContext context) {
    final fractions = dailyEmotionCounts.map(dayMoodFractions).toList();
    final dayZero = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: CustomPaint(
          painter: _MentalWavePainter(fractions: fractions),
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

class _MentalWavePainter extends CustomPainter {
  final List<DayMoodFractions> fractions;

  _MentalWavePainter({required this.fractions});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = MentalWaveChart._backdrop,
    );

    const topPad = 20.0;
    const bottomPad = 36.0;
    final plotTop = topPad;
    final plotBottom = size.height - bottomPad;
    final baselineY = (plotTop + plotBottom) / 2;
    final amplitude = (plotBottom - plotTop) / 2 * 0.88;
    final n = fractions.length;
    if (n == 0) return;
    final stepX = n <= 1 ? size.width : size.width / (n - 1);
    double xFor(int i) => i * stepX;

    // 基準線（真ん中）。
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );

    _drawWave(
      canvas,
      size,
      values: [for (final f in fractions) f.positive],
      xFor: xFor,
      stepX: stepX,
      baselineY: baselineY,
      amplitude: amplitude,
      direction: -1,
      color: MentalWaveChart.positiveColor,
    );
    _drawWave(
      canvas,
      size,
      values: [for (final f in fractions) f.negative],
      xFor: xFor,
      stepX: stepX,
      baselineY: baselineY,
      amplitude: amplitude,
      direction: 1,
      color: MentalWaveChart.negativeColor,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required List<double?> values,
    required double Function(int) xFor,
    required double stepX,
    required double baselineY,
    required double amplitude,
    required double direction,
    required Color color,
  }) {
    final n = values.length;
    double yFor(double value) => baselineY + direction * value * amplitude;

    final knownIndices = [for (var i = 0; i < n; i++) if (values[i] != null) i];

    final List<Offset> samplePoints;
    if (knownIndices.isEmpty) {
      samplePoints = [Offset(0, baselineY), Offset(size.width, baselineY)];
    } else if (knownIndices.length == 1) {
      final y = yFor(values[knownIndices.first]!);
      samplePoints = [Offset(0, y), Offset(size.width, y)];
    } else {
      final knownPts = [
        for (final i in knownIndices) Offset(xFor(i), yFor(values[i]!)),
      ];
      samplePoints = [
        Offset(0, knownPts.first.dy),
        ..._catmullRomSample(knownPts),
        Offset(size.width, knownPts.last.dy),
      ];
    }

    final linePath = Path()..moveTo(samplePoints.first.dx, samplePoints.first.dy);
    for (final p in samplePoints.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(samplePoints.last.dx, baselineY)
      ..lineTo(samplePoints.first.dx, baselineY)
      ..close();

    canvas.drawPath(fillPath, Paint()..style = PaintingStyle.fill..color = color.withValues(alpha: 0.32));
    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    for (final i in knownIndices) {
      final point = Offset(xFor(i), yFor(values[i]!));
      canvas.drawCircle(point, 4.5, Paint()..color = color);
      canvas.drawCircle(
        point,
        4.5,
        Paint()
          ..color = MentalWaveChart._backdrop
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MentalWavePainter oldDelegate) {
    return oldDelegate.fractions != fractions;
  }
}

/// Catmull-Romスプラインで、与えられた制御点を滑らかに通過する曲線上の点列を
/// 生成する（両端は前後の区間を反転して仮想制御点とする標準的な手法）。
List<Offset> _catmullRomSample(List<Offset> pts, {int samplesPerSegment = 20}) {
  if (pts.length < 2) return pts;
  final extended = <Offset>[
    pts[0] * 2 - pts[1],
    ...pts,
    pts[pts.length - 1] * 2 - pts[pts.length - 2],
  ];
  final result = <Offset>[];
  for (var i = 1; i < extended.length - 2; i++) {
    final p0 = extended[i - 1];
    final p1 = extended[i];
    final p2 = extended[i + 1];
    final p3 = extended[i + 2];
    final startJ = i == 1 ? 0 : 1;
    for (var j = startJ; j <= samplesPerSegment; j++) {
      final t = j / samplesPerSegment;
      result.add(_catmullRomPoint(p0, p1, p2, p3, t));
    }
  }
  return result;
}

Offset _catmullRomPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final t2 = t * t;
  final t3 = t2 * t;
  final x = 0.5 *
      ((2 * p1.dx) +
          (-p0.dx + p2.dx) * t +
          (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
          (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
  final y = 0.5 *
      ((2 * p1.dy) +
          (-p0.dy + p2.dy) * t +
          (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
          (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
  return Offset(x, y);
}
