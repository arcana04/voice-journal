import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/weekly_report.dart';
import 'emotion_bubble.dart';

/// 波の1つの山（＝1つ以上の記録が近い時刻に集まったもの）。タップすると
/// [moments]の一覧をボトムシートで見せるので、1日に大量に記録した日でも
/// 波自体はごちゃつかず、詳細はタップで確認できる。
class _MoodCluster {
  final double x;
  final List<MoodMoment> moments;

  const _MoodCluster({required this.x, required this.moments});
}

/// 近い時刻（＝近いピクセル位置）の記録を1つの山にまとめる。閾値以内の記録が
/// 連続する限りどんどん同じ山に含める（チェーン結合）。
List<_MoodCluster> _clusterMoments(
  List<MoodMoment> series,
  DateTime weekStart,
  double width, {
  double thresholdPx = 14,
}) {
  if (series.isEmpty) return [];
  const weekMs = 7 * 24 * 60 * 60 * 1000;
  double xForTime(DateTime t) {
    final fraction = t.difference(weekStart).inMilliseconds / weekMs;
    return fraction.clamp(0.0, 1.0) * width;
  }

  final sorted = [...series]..sort((a, b) => a.time.compareTo(b.time));
  final clusters = <_MoodCluster>[];
  var bucket = <MoodMoment>[sorted.first];
  var bucketXs = <double>[xForTime(sorted.first.time)];

  for (var i = 1; i < sorted.length; i++) {
    final x = xForTime(sorted[i].time);
    if (x - bucketXs.last <= thresholdPx) {
      bucket.add(sorted[i]);
      bucketXs.add(x);
    } else {
      clusters.add(_MoodCluster(
        x: bucketXs.reduce((a, b) => a + b) / bucketXs.length,
        moments: bucket,
      ));
      bucket = [sorted[i]];
      bucketXs = [x];
    }
  }
  clusters.add(_MoodCluster(
    x: bucketXs.reduce((a, b) => a + b) / bucketXs.length,
    moments: bucket,
  ));
  return clusters;
}

/// 週刊脳内レポートの「メンタルウェーブ」。ポジティブ（オレンジ）とネガティブ
/// （パープル）、それぞれ実際の記録時刻ごとに丘を描く。近い時刻の記録は1つの
/// 山にまとめる（＝1日に大量に記録してもグラフがごちゃつかない）ので、山を
/// タップすると、その山を構成する記録の一覧（時刻＋感情タグ）を確認できる。
class MentalWaveChart extends StatefulWidget {
  final List<MoodMoment> moments;
  final DateTime weekStart;
  final String locale;

  const MentalWaveChart({
    super.key,
    required this.moments,
    required this.weekStart,
    required this.locale,
  });

  static const Color _backdrop = Color(0xFF10162B);
  static const Color positiveColor = Color(0xFFF2A93B);
  static const Color negativeColor = Color(0xFF8B90F0);

  @override
  State<MentalWaveChart> createState() => _MentalWaveChartState();
}

class _MentalWaveChartState extends State<MentalWaveChart> {
  @override
  Widget build(BuildContext context) {
    final dayZero =
        DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final positiveMoments =
                widget.moments.where((m) => m.tag.category == EmotionCategory.positive).toList();
            final negativeMoments =
                widget.moments.where((m) => m.tag.category == EmotionCategory.negative).toList();
            final positiveClusters = _clusterMoments(positiveMoments, dayZero, width);
            final negativeClusters = _clusterMoments(negativeMoments, dayZero, width);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(
                context,
                details.localPosition,
                positiveClusters,
                negativeClusters,
              ),
              child: CustomPaint(
                painter: _MentalWavePainter(
                  positiveClusters: positiveClusters,
                  negativeClusters: negativeClusters,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Text(
                          DateFormat.E(widget.locale).format(dayZero.add(Duration(days: i))),
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
            );
          },
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    Offset tapPosition,
    List<_MoodCluster> positiveClusters,
    List<_MoodCluster> negativeClusters,
  ) {
    final layout = _layoutMetrics(context.size ?? Size.zero);
    _MoodCluster? nearest;
    var nearestDist = double.infinity;
    double peakYFor(double amplitude, int direction) => layout.centerY + direction * amplitude;

    for (final c in positiveClusters) {
      final d = (Offset(c.x, peakYFor(layout.amplitude, -1)) - tapPosition).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearest = c;
      }
    }
    for (final c in negativeClusters) {
      final d = (Offset(c.x, peakYFor(layout.amplitude, 1)) - tapPosition).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearest = c;
      }
    }

    const hitRadius = 28.0;
    if (nearest != null && nearestDist <= hitRadius) {
      _showClusterSheet(context, nearest);
    }
  }

  _WaveLayoutMetrics _layoutMetrics(Size size) {
    const topPad = 20.0;
    const bottomPad = 36.0;
    final plotTop = topPad;
    final plotBottom = size.height - bottomPad;
    final plotHeight = plotBottom - plotTop;
    return _WaveLayoutMetrics(
      centerY: plotTop + plotHeight / 2,
      amplitude: plotHeight / 2 - 6,
    );
  }

  void _showClusterSheet(BuildContext context, _MoodCluster cluster) {
    final l10n = AppLocalizations.of(context)!;
    final moments = [...cluster.moments]..sort((a, b) => a.time.compareTo(b.time));
    final accent = moments.first.tag.category == EmotionCategory.negative
        ? MentalWaveChart.negativeColor
        : MentalWaveChart.positiveColor;
    final headerDate =
        '${DateFormat('M/d', widget.locale).format(moments.first.time)}(${DateFormat.E(widget.locale).format(moments.first.time)})';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF181D34),
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
            ),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          headerDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: moments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = moments[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: m.tag.color.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: EmotionBubble(tag: m.tag, size: 26)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.tag.labelFor(l10n),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat.Hm(widget.locale).format(m.time),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveLayoutMetrics {
  final double centerY;
  final double amplitude;

  const _WaveLayoutMetrics({required this.centerY, required this.amplitude});
}

class _MentalWavePainter extends CustomPainter {
  final List<_MoodCluster> positiveClusters;
  final List<_MoodCluster> negativeClusters;

  _MentalWavePainter({required this.positiveClusters, required this.negativeClusters});

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
    final plotHeight = plotBottom - plotTop;
    final centerY = plotTop + plotHeight / 2;
    final amplitude = plotHeight / 2 - 6;

    // 曜日ごとの列がわかるよう、各日の開始位置に薄い縦の点線を引く。
    for (var i = 0; i < 7; i++) {
      _drawDashedVerticalLine(
        canvas,
        x: size.width * i / 7,
        top: plotTop - 6,
        bottom: plotBottom,
        paint: Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = 1,
      );
    }

    _drawWave(
      canvas,
      size,
      clusters: positiveClusters,
      centerY: centerY,
      amplitude: amplitude,
      direction: -1,
      color: MentalWaveChart.positiveColor,
    );
    _drawWave(
      canvas,
      size,
      clusters: negativeClusters,
      centerY: centerY,
      amplitude: amplitude,
      direction: 1,
      color: MentalWaveChart.negativeColor,
    );
  }

  void _drawDashedVerticalLine(
    Canvas canvas, {
    required double x,
    required double top,
    required double bottom,
    required Paint paint,
    double dashLength = 4,
    double gapLength = 4,
  }) {
    var y = top;
    while (y < bottom) {
      final segmentEnd = (y + dashLength).clamp(top, bottom);
      canvas.drawLine(Offset(x, y), Offset(x, segmentEnd), paint);
      y = segmentEnd + gapLength;
    }
  }

  /// クラスターごとに、両端で傾きが0になるS字カーブ(smoothstep)の滑らかな
  /// 山を作り、複数の山が重なる位置ではその最大値を採用して波形全体を作る。
  /// 山が孤立している区間は自然に中央ラインへ収束するため、記録の無い区間
  /// との継ぎ目に鋭いV字の谷ができない。近い山同士は自然に1つの丘へ繋がる。
  static const double _riseWidth = 48;

  double _smoothstep(double t) {
    final c = t.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  List<Offset> _sampleWave(
    List<_MoodCluster> clusters,
    double width,
    double centerY,
    double amplitude,
    double direction,
  ) {
    if (clusters.isEmpty) {
      return [Offset(0, centerY), Offset(width, centerY)];
    }
    final xs = [for (final c in clusters) c.x];
    double heightAt(double x) {
      var maxT = 0.0;
      for (final cx in xs) {
        final d = (x - cx).abs();
        if (d >= _riseWidth) continue;
        final t = _smoothstep(1 - d / _riseWidth);
        if (t > maxT) maxT = t;
      }
      return maxT;
    }

    const step = 4.0;
    final points = <Offset>[];
    for (var x = 0.0; x < width; x += step) {
      points.add(Offset(x, centerY + direction * amplitude * heightAt(x)));
    }
    points.add(Offset(width, centerY + direction * amplitude * heightAt(width)));
    return points;
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required List<_MoodCluster> clusters,
    required double centerY,
    required double amplitude,
    required double direction,
    required Color color,
  }) {
    final samplePoints = _sampleWave(clusters, size.width, centerY, amplitude, direction);

    final linePath = Path()..moveTo(samplePoints.first.dx, samplePoints.first.dy);
    for (final p in samplePoints.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(samplePoints.last.dx, centerY)
      ..lineTo(samplePoints.first.dx, centerY)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final peakY = centerY + direction * amplitude;
    for (final c in clusters) {
      final count = c.moments.length;
      final radius = count > 1 ? 9.0 : 4.5;
      canvas.drawCircle(Offset(c.x, peakY), radius, Paint()..color = color);
      canvas.drawCircle(
        Offset(c.x, peakY),
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      if (count > 1) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(c.x - textPainter.width / 2, peakY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MentalWavePainter oldDelegate) {
    return oldDelegate.positiveClusters != positiveClusters ||
        oldDelegate.negativeClusters != negativeClusters;
  }
}
