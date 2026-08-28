import 'dart:math' as math;

import 'package:flutter/material.dart';

class CategorySlice {
  final String label;
  final int value;
  final Color color;

  const CategorySlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 3カテゴリ（日記/アイデア/タスク）の仕分け比率を示すドーナツチャート。
/// 色だけに頼らないよう、常に凡例で件数・割合を直接ラベル表示する。
class CategoryDonutChart extends StatelessWidget {
  final List<CategorySlice> slices;

  const CategoryDonutChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 108,
          height: 108,
          child: CustomPaint(
            painter: _DonutPainter(
              slices: slices,
              total: total,
              trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slice.label,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        total == 0
                            ? '0%'
                            : '${(slice.value / total * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategorySlice> slices;
  final int total;
  final Color trackColor;

  _DonutPainter({
    required this.slices,
    required this.total,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const strokeWidth = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (total == 0) return;

    var startAngle = -math.pi / 2;
    const gap = 0.03;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final drawSweep = (sweep - gap).clamp(0.0, sweep);
      canvas.drawArc(rect, startAngle + gap / 2, drawSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.total != total;
  }
}
