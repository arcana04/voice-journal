import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';

/// 「脳内マップ」の簡易版。17種の感情タグをポジティブ/ノーマル/ネガティブの
/// 3カテゴリに畳み込み、週トータルに占める割合を円の大きさで示す。
/// 位置はカテゴリ固定（ポジティブ=右上/ノーマル=左/ネガティブ=右下）にして、
/// 週をまたいでも同じ場所を見れば比較できるようにしている。
class EmotionCategoryBreakdown extends StatelessWidget {
  final Map<EmotionTag, int> emotionCounts;

  const EmotionCategoryBreakdown({super.key, required this.emotionCounts});

  static const double _minRadius = 42;
  static const double _maxRadius = 82;
  static const double _height = 200;

  // ライト/ダークそれぞれのチャート面でコントラスト検証済みの3色
  // （dataviz skillのvalidate_palette.jsでlight/dark両方PASS）。
  // 感情タグの色相ファミリー（positive=暖色/fine=緑系/negative=青系）に揃えている。
  static const Map<EmotionCategory, Color> _lightColors = {
    EmotionCategory.positive: Color(0xFFE76423),
    EmotionCategory.fine: Color(0xFF2BAB76),
    EmotionCategory.negative: Color(0xFF3156C4),
  };
  static const Map<EmotionCategory, Color> _darkColors = {
    EmotionCategory.positive: Color(0xFFC96E36),
    EmotionCategory.fine: Color(0xFF2F9F76),
    EmotionCategory.negative: Color(0xFF4C6FD1),
  };

  // 円の中心位置（コンテナ幅・高さに対する比率）。カテゴリ固定にすることで、
  // 割合が変わっても「どこを見ればどの感情か」が週をまたいで変わらない。
  static const Map<EmotionCategory, Alignment> _anchors = {
    EmotionCategory.positive: Alignment(0.32, -0.62),
    EmotionCategory.fine: Alignment(-0.58, 0.28),
    EmotionCategory.negative: Alignment(0.42, 0.68),
  };

  String _labelFor(AppLocalizations l10n, EmotionCategory category) => switch (category) {
        EmotionCategory.positive => l10n.emotionCategoryPositive,
        EmotionCategory.fine => l10n.emotionCategoryNormal,
        EmotionCategory.negative => l10n.emotionCategoryNegative,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = dark ? _darkColors : _lightColors;

    final categoryCounts = <EmotionCategory, int>{
      for (final c in EmotionCategory.values) c: 0,
    };
    var total = 0;
    for (final entry in emotionCounts.entries) {
      categoryCounts[entry.key.category] =
          (categoryCounts[entry.key.category] ?? 0) + entry.value;
      total += entry.value;
    }

    if (total == 0) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            l10n.weeklyReportNoEmotionData,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final slices = [
      for (final category in EmotionCategory.values)
        _CategorySlice(
          category: category,
          label: _labelFor(l10n, category),
          count: categoryCounts[category] ?? 0,
          percent: (categoryCounts[category] ?? 0) / total,
          color: colors[category]!,
        ),
    ];
    final maxPercent = slices.map((s) => s.percent).reduce(math.max);

    return Column(
      children: [
        SizedBox(
          height: _height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final slice in slices)
                    _positioned(slice, maxPercent, constraints.biggest),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (final slice in slices) _LegendItem(slice: slice)],
        ),
      ],
    );
  }

  Widget _positioned(_CategorySlice slice, double maxPercent, Size size) {
    final normalized = maxPercent <= 0 ? 0.0 : math.sqrt(slice.percent / maxPercent);
    final radius = _minRadius + (_maxRadius - _minRadius) * normalized.clamp(0.0, 1.0);
    final anchor = _anchors[slice.category]!;
    final center = anchor.withinRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final maxLeft = math.max(0.0, size.width - radius * 2);
    final maxTop = math.max(0.0, size.height - radius * 2);
    return Positioned(
      left: (center.dx - radius).clamp(0.0, maxLeft),
      top: (center.dy - radius).clamp(0.0, maxTop),
      width: radius * 2,
      height: radius * 2,
      child: _Bubble(slice: slice, radius: radius),
    );
  }
}

class _CategorySlice {
  final EmotionCategory category;
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _CategorySlice({
    required this.category,
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });
}

class _Bubble extends StatelessWidget {
  final _CategorySlice slice;
  final double radius;

  const _Bubble({required this.slice, required this.radius});

  @override
  Widget build(BuildContext context) {
    final fontSize = (radius * 0.34).clamp(14.0, 24.0);
    final percentText = '${(slice.percent * 100).round()}%';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: radius * 0.35,
            offset: Offset(0, radius * 0.1),
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            Color.lerp(slice.color, Colors.white, 0.35)!,
            slice.color,
            Color.lerp(slice.color, Colors.black, 0.15)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        percentText,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final _CategorySlice slice;

  const _LegendItem({required this.slice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(slice.label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${(slice.percent * 100).round()}%',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
