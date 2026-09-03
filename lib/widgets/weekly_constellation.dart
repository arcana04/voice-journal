import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/weekly_report.dart';

const Color _kConstellationBackdrop = Color(0xFF080B1F);

/// 週刊脳内レポートの「感情の星座」。1週間分の記録それぞれを、記録時刻
/// (横軸=月〜日+時間帯)と感情カテゴリ(縦軸=ポジティブ上/ふつう中央/
/// ネガティブ下)で位置づけた星として夜空に配置し、記録順に細い光の線で
/// つないで「その週だけの星座」を描く。オーロラの後継として、日ごとの
/// 集計ではなく記録1件1件を主役にした可視化にしている。
class WeeklyConstellation extends StatelessWidget {
  final List<MoodMoment> moments;
  final DateTime weekStart;
  final String locale;

  const WeeklyConstellation({
    super.key,
    required this.moments,
    required this.weekStart,
    required this.locale,
  });

  static const double _height = 240;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayZero = DateTime(weekStart.year, weekStart.month, weekStart.day);

    if (moments.isEmpty) {
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

    final sorted = [...moments]..sort((a, b) => a.time.compareTo(b.time));

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ConstellationPainter(moments: sorted, dayZero: dayZero),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Text(
                    DateFormat.E(locale).format(dayZero.add(Duration(days: i))),
                    style: const TextStyle(
                      color: Colors.white54,
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

class _StarPoint {
  final Offset pos; // 0..1 正規化座標(横=週内の時間経過、縦=感情の高さ)
  final Color color;
  final double radius;

  const _StarPoint({required this.pos, required this.color, required this.radius});
}

class _ConstellationPainter extends CustomPainter {
  final List<MoodMoment> moments;
  final DateTime dayZero;

  _ConstellationPainter({required this.moments, required this.dayZero});

  static const double _minRadius = 3.0;
  static const double _maxRadius = 7.5;

  /// カテゴリごとの縦帯(0=上端/1=下端)。同じ感情タグは常にカテゴリ内の同じ
  /// 位置に来るようにして、週をまたいでも「この高さ=この感情」というパターン
  /// が掴みやすいようにする。
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

  double _xFor(DateTime time) {
    final dayIndex = time.difference(dayZero).inDays.clamp(0, 6);
    final hourFraction = (time.hour * 60 + time.minute) / (24 * 60);
    return (dayIndex + hourFraction) / 7;
  }

  double _radiusFor(int textLength) {
    final normalized = math.sqrt(textLength.clamp(0, 200) / 200);
    return _minRadius + (_maxRadius - _minRadius) * normalized;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = _kConstellationBackdrop,
    );

    // 背景にうっすら瞬く小さな星。
    final starRng = math.Random(7);
    for (var i = 0; i < 50; i++) {
      final x = starRng.nextDouble() * size.width;
      final y = starRng.nextDouble() * size.height;
      final r = 0.5 + starRng.nextDouble() * 0.8;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.1 + starRng.nextDouble() * 0.22),
      );
    }

    if (moments.isEmpty) return;

    // 左右に少し余白を取り、日曜の星が枠ギリギリに張り付かないようにする。
    Offset toCanvas(Offset p) => Offset((p.dx * 0.86 + 0.07) * size.width, p.dy * size.height);

    final points = [
      for (final m in moments)
        _StarPoint(
          pos: Offset(_xFor(m.time), _yFor(m.tag)),
          color: m.tag.color,
          radius: _radiusFor(m.textLength),
        ),
    ];

    // 星座のライン: 記録順に、星Aの色から星Bの色へグラデーションする細い光の線。
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final pa = toCanvas(a.pos);
      final pb = toCanvas(b.pos);
      canvas.drawLine(
        pa,
        pb,
        Paint()
          ..shader = ui.Gradient.linear(pa, pb, [
            a.color.withValues(alpha: 0.85),
            b.color.withValues(alpha: 0.85),
          ])
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8)
          ..blendMode = BlendMode.plus,
      );
    }

    // 星本体: 外側の柔らかいグロー + 白い芯 + 感情色のコア + きらめきの十字線。
    // 強い感情(=本文が長い記録)ほど半径が大きく、グローも強くなる。
    for (final p in points) {
      final c = toCanvas(p.pos);
      canvas.drawCircle(
        c,
        p.radius * 2.6,
        Paint()
          ..color = p.color.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 1.4)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(c, p.radius, Paint()..color = Colors.white.withValues(alpha: 0.95));
      canvas.drawCircle(c, p.radius * 0.6, Paint()..color = p.color);

      final glintLen = p.radius * 2.4;
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 1.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawLine(c - Offset(glintLen, 0), c + Offset(glintLen, 0), glintPaint);
      canvas.drawLine(c - Offset(0, glintLen), c + Offset(0, glintLen), glintPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.moments != moments;
  }
}
