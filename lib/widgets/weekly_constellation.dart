import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/weekly_report.dart';

const Color _kConstellationBackdrop = Color(0xFF080B1F);

/// 左端に「Positive/Neutral/Negative」軸ラベルを表示するための余白と、
/// 右端の余白。データを実際にプロットする領域はこの余白の内側になる。
const double _kAxisGutter = 66;
const double _kRightPad = 14;

/// 週刊脳内レポートの「感情グラフ」。1週間分の記録それぞれを、記録時刻
/// (横軸=月〜日+時間帯)と感情カテゴリ(縦軸=ポジティブ上/ふつう中央/
/// ネガティブ下)で位置づけた点として夜空に配置し、記録順に光の線で
/// つなぐ。点をタップするとその記録の感情と時刻を吹き出しで表示する。
class WeeklyConstellation extends StatefulWidget {
  final List<MoodMoment> moments;
  final DateTime weekStart;
  final String locale;

  const WeeklyConstellation({
    super.key,
    required this.moments,
    required this.weekStart,
    required this.locale,
  });

  @override
  State<WeeklyConstellation> createState() => _WeeklyConstellationState();
}

class _WeeklyConstellationState extends State<WeeklyConstellation>
    with SingleTickerProviderStateMixin {
  static const double _height = 420;

  int? _selectedIndex;

  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 700 + widget.moments.length * 120),
  )..forward();

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  (double, double) _bandFor(EmotionCategory category) => switch (category) {
        EmotionCategory.positive => (0.14, 0.34),
        EmotionCategory.fine => (0.44, 0.58),
        EmotionCategory.negative => (0.68, 0.90),
      };

  double _yFor(EmotionTag tag) {
    final band = _bandFor(tag.category);
    final siblings = EmotionTag.values.where((t) => t.category == tag.category).toList();
    final index = siblings.indexOf(tag);
    final t = siblings.length <= 1 ? 0.5 : index / (siblings.length - 1);
    return band.$1 + (band.$2 - band.$1) * t;
  }

  double _xFor(DateTime time, DateTime dayZero) {
    final dayIndex = time.difference(dayZero).inDays.clamp(0, 6);
    final hourFraction = (time.hour * 60 + time.minute) / (24 * 60);
    return (dayIndex + hourFraction) / 7;
  }

  Offset _toCanvas(Offset normalized, Size size) {
    final plotWidth = size.width - _kAxisGutter - _kRightPad;
    return Offset(
      _kAxisGutter + normalized.dx * plotWidth,
      normalized.dy * size.height,
    );
  }

  List<_StarPoint> _buildPoints(List<MoodMoment> sorted, DateTime dayZero, Size size) {
    return [
      for (final m in sorted)
        _StarPoint(
          moment: m,
          canvasPos: _toCanvas(Offset(_xFor(m.time, dayZero), _yFor(m.tag)), size),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayZero = DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day);

    if (widget.moments.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kConstellationBackdrop,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.weeklyReportNoEmotionData,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final sorted = [...widget.moments]..sort((a, b) => a.time.compareTo(b.time));

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final points = _buildPoints(sorted, dayZero, size);

            void handleTap(Offset local) {
              var bestIndex = -1;
              var bestDist = double.infinity;
              for (var i = 0; i < points.length; i++) {
                final d = (points[i].canvasPos - local).distance;
                if (d < bestDist) {
                  bestDist = d;
                  bestIndex = i;
                }
              }
              const tolerance = 28.0;
              setState(() {
                if (bestIndex == -1 || bestDist > tolerance) {
                  _selectedIndex = null;
                } else {
                  _selectedIndex = _selectedIndex == bestIndex ? null : bestIndex;
                }
              });
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => handleTap(details.localPosition),
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _ConstellationPainter(
                      points: points,
                      plotLeft: _kAxisGutter,
                      reveal: _revealController,
                    ),
                  ),
                  _axisLabels(l10n, size),
                  _dayLabels(dayZero, size),
                  if (_selectedIndex != null && _selectedIndex! < points.length)
                    _tooltip(points[_selectedIndex!], size),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _axisLabels(AppLocalizations l10n, Size size) {
    final entries = [
      (l10n.emotionCategoryPositive, _bandFor(EmotionCategory.positive)),
      (l10n.emotionCategoryNormal, _bandFor(EmotionCategory.fine)),
      (l10n.emotionCategoryNegative, _bandFor(EmotionCategory.negative)),
    ];
    return Stack(
      children: [
        for (final entry in entries)
          Positioned(
            left: 14,
            top: ((entry.$2.$1 + entry.$2.$2) / 2) * size.height - 8,
            child: Text(
              entry.$1,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dayLabels(DateTime dayZero, Size size) {
    return Positioned(
      left: _kAxisGutter,
      right: _kRightPad,
      bottom: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 7; i++)
            Text(
              DateFormat.E(widget.locale).format(dayZero.add(Duration(days: i))),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tooltip(_StarPoint point, Size size) {
    final l10n = AppLocalizations.of(context)!;
    final label = point.moment.tag.labelFor(l10n);
    final timeLabel =
        '${DateFormat.MMMd(widget.locale).format(point.moment.time)} ${DateFormat.Hm(widget.locale).format(point.moment.time)}';
    const bubbleWidth = 132.0;
    final left = (point.canvasPos.dx - bubbleWidth / 2)
        .clamp(4.0, math.max(4.0, size.width - bubbleWidth - 4))
        .toDouble();
    final top = math.max(4.0, point.canvasPos.dy - 54);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: bubbleWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: point.moment.tag.color.withValues(alpha: 0.65)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: point.moment.tag.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarPoint {
  final MoodMoment moment;
  final Offset canvasPos;

  const _StarPoint({required this.moment, required this.canvasPos});
}

class _ConstellationPainter extends CustomPainter {
  final List<_StarPoint> points;
  final double plotLeft;
  final Animation<double> reveal;

  _ConstellationPainter({
    required this.points,
    required this.plotLeft,
    required this.reveal,
  }) : super(repaint: reveal);

  static const double _pointRadius = 5.5;

  /// 各点のポップイン演出に使う進捗の幅。最後の点にもこの分の「間」を
  /// 残しておかないと、最後の点だけ登場のタイミングがアニメーション終了
  /// 時刻とぴったり重なってしまい、ポップインが一切進まないまま(=不可視の
  /// まま)止まってしまう。
  double get _popWindow =>
      points.length <= 1 ? 0.6 : (1.0 / (points.length - 1)) * 0.7;

  /// 点iが「古い順から線が引かれてくる」演出の中で登場すべき進捗(0..1)。
  /// 最後の点の登場タイミングを1.0より前(1.0 - _popWindow)に前倒しして、
  /// 全ての点がポップイン用の「間」を確保できるようにする。
  double _targetFor(int i) {
    if (points.length <= 1) return 0.0;
    final span = (1.0 - _popWindow).clamp(0.0, 1.0);
    return (i / (points.length - 1)) * span;
  }

  void _paintAuroraWave(Canvas canvas, Size size) {
    void wave(double baseY, double amplitude, double phase, Color color) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, baseY);
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = t * size.width;
        final y = baseY + math.sin(t * math.pi * 2 + phase) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, baseY - amplitude),
          Offset(0, size.height),
          [color.withValues(alpha: 0.32), color.withValues(alpha: 0.0)],
        );
      canvas.drawPath(path, paint);
    }

    wave(size.height * 0.40, 26, 0.6, const Color(0xFF6B4A26));
    wave(size.height * 0.60, 30, 2.4, const Color(0xFF203A63));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = _kConstellationBackdrop,
    );

    _paintAuroraWave(canvas, size);

    // 曜日ごとの区切り線(データをプロットする領域の内側のみ)。
    final plotRight = size.width - _kRightPad;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.0;
    for (var i = 0; i <= 7; i++) {
      final x = plotLeft + (plotRight - plotLeft) * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (points.isEmpty) return;

    final progress = reveal.value.clamp(0.0, 1.0);

    // 感情グラフのライン: 記録の古い順に、点Aの色から点Bの色へグラデーション
    // する光の線が伸びてくる。
    for (var i = 0; i < points.length - 1; i++) {
      final tA = _targetFor(i);
      final tB = _targetFor(i + 1);
      if (progress <= tA) break;
      final segProgress =
          tB > tA ? ((progress - tA) / (tB - tA)).clamp(0.0, 1.0) : 1.0;
      if (segProgress <= 0.0) continue;
      final a = points[i];
      final b = points[i + 1];
      final endPos = Offset.lerp(a.canvasPos, b.canvasPos, segProgress)!;
      canvas.drawLine(
        a.canvasPos,
        endPos,
        Paint()
          ..shader = ui.Gradient.linear(a.canvasPos, endPos, [
            a.moment.tag.color.withValues(alpha: 0.85),
            b.moment.tag.color.withValues(alpha: 0.85),
          ])
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8)
          ..blendMode = BlendMode.plus,
      );
    }

    // 点本体: 線がその点まで届いたタイミングでちょっと弾みながらポップイン
    // する。外側の柔らかいグロー + 感情色で塗りつぶしたコア。
    for (var i = 0; i < points.length; i++) {
      final t = _targetFor(i);
      if (progress < t) continue;
      final localP = _popWindow > 0
          ? ((progress - t) / _popWindow).clamp(0.0, 1.0)
          : 1.0;
      final scale = Curves.easeOutBack.transform(localP).clamp(0.0, 1.3);
      if (scale <= 0.0) continue;
      final p = points[i];
      final c = p.canvasPos;
      final color = p.moment.tag.color;
      final r = _pointRadius * scale;
      canvas.drawCircle(
        c,
        r * 2.6,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.4)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(c, r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
