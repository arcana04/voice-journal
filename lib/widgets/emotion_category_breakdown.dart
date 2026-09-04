import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';

/// 「脳内マップ」の簡易版。17種の感情タグをポジティブ/ノーマル/ネガティブの
/// 3カテゴリに畳み込み、週トータルに占める割合を円の大きさで示す。
/// 位置はカテゴリ固定（ポジティブ=右上/ノーマル=左/ネガティブ=右下）にして、
/// 週をまたいでも同じ場所を見れば比較できるようにしている。
class EmotionCategoryBreakdown extends StatefulWidget {
  final Map<EmotionTag, int> emotionCounts;

  const EmotionCategoryBreakdown({super.key, required this.emotionCounts});

  @override
  State<EmotionCategoryBreakdown> createState() => _EmotionCategoryBreakdownState();
}

class _EmotionCategoryBreakdownState extends State<EmotionCategoryBreakdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const double _minRadius = 40;
  static const double _maxRadius = 74;
  static const double _height = 260;

  // positive=赤/fine=緑/negative=紺、とひと目でわかる原色に近い塗り。
  static const Map<EmotionCategory, Color> _lightColors = {
    EmotionCategory.positive: Color(0xFFE0342B),
    EmotionCategory.fine: Color(0xFF1FA971),
    EmotionCategory.negative: Color(0xFF1B3A78),
  };
  static const Map<EmotionCategory, Color> _darkColors = {
    EmotionCategory.positive: Color(0xFFE0483A),
    EmotionCategory.fine: Color(0xFF29B37E),
    EmotionCategory.negative: Color(0xFF2A4C96),
  };

  // 円の中心位置（コンテナ幅・高さに対する比率）。3つの中心が三角形を
  // 描くように配置（positive=上/fine=左下/negative=右下）。カテゴリ固定に
  // することで、割合が変わっても「どこを見ればどの感情か」が週をまたいで
  // 変わらない。
  static const Map<EmotionCategory, Alignment> _anchors = {
    EmotionCategory.positive: Alignment(0.0, -0.75),
    EmotionCategory.fine: Alignment(-0.75, 0.55),
    EmotionCategory.negative: Alignment(0.75, 0.55),
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
    for (final entry in widget.emotionCounts.entries) {
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
              final circles = _layoutCircles(slices, maxPercent, constraints.biggest);
              return Stack(
                children: [
                  for (var i = 0; i < circles.length; i++)
                    _circleWidget(circles[i], dark, i, circles.length),
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

  double _radiusFor(_CategorySlice slice, double maxPercent) {
    final normalized = maxPercent <= 0 ? 0.0 : math.sqrt(slice.percent / maxPercent);
    return _minRadius + (_maxRadius - _minRadius) * normalized.clamp(0.0, 1.0);
  }

  /// カテゴリ固定のアンカー位置から出発しつつ、実際の半径同士が重なる場合は
  /// 中心同士を引き離して衝突を解消する（大きい円ほどアンカーからのズレが
  /// 大きくなるが、"positive=右上/normal=左/negative=右下" のおおまかな
  /// 位置関係は保たれる）。
  List<_CircleLayout> _layoutCircles(
    List<_CategorySlice> slices,
    double maxPercent,
    Size size,
  ) {
    final circles = [
      for (final slice in slices)
        _CircleLayout(
          slice: slice,
          radius: _radiusFor(slice, maxPercent),
          center: _anchors[slice.category]!.withinRect(
            Rect.fromLTWH(0, 0, size.width, size.height),
          ),
        ),
    ];

    const gap = 10.0;
    for (var iteration = 0; iteration < 16; iteration++) {
      var moved = false;
      for (var i = 0; i < circles.length; i++) {
        for (var j = i + 1; j < circles.length; j++) {
          final a = circles[i];
          final b = circles[j];
          final delta = b.center - a.center;
          final minDist = a.radius + b.radius + gap;
          final distance = delta.distance;
          if (distance < minDist) {
            moved = true;
            final direction = distance < 0.01 ? const Offset(1, 0) : delta / distance;
            final push = (minDist - distance) / 2;
            a.center -= direction * push;
            b.center += direction * push;
          }
        }
      }
      if (!moved) break;
    }

    for (final circle in circles) {
      final maxX = math.max(circle.radius, size.width - circle.radius);
      final maxY = math.max(circle.radius, size.height - circle.radius);
      circle.center = Offset(
        circle.center.dx.clamp(circle.radius, maxX),
        circle.center.dy.clamp(circle.radius, maxY),
      );
    }

    return circles;
  }

  Widget _circleWidget(_CircleLayout circle, bool dark, int index, int count) {
    // 円ごとに開始タイミングを少しずつずらし、中心から膨らむように登場させる。
    final start = (index / count) * 0.5;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return Positioned(
      left: circle.center.dx - circle.radius,
      top: circle.center.dy - circle.radius,
      width: circle.radius * 2,
      height: circle.radius * 2,
      child: AnimatedBuilder(
        animation: entrance,
        builder: (context, child) {
          final v = entrance.value;
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: v.clamp(0.0, 1.3), child: child),
          );
        },
        child: _Bubble(slice: circle.slice, radius: circle.radius, dark: dark),
      ),
    );
  }
}

class _CircleLayout {
  final _CategorySlice slice;
  final double radius;
  Offset center;

  _CircleLayout({required this.slice, required this.radius, required this.center});
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
  final bool dark;

  const _Bubble({required this.slice, required this.radius, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fontSize = (radius * 0.34).clamp(14.0, 24.0);
    final percentText = '${(slice.percent * 100).round()}%';
    final base = slice.color;
    // 縁の色は塗りと同じ色相のまま、より濃くする。ライト/ダークどちらの
    // 背景でも塗りより暗い輪郭になるので、はっきりした境界として読める。
    final rim = Color.lerp(base, Colors.black, 0.45)!;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // 色付きグローは暗い背景でこそ「発光」に見える。ライトモードだと
          // 白地ににじんだシミのように見えてしまうため、ダークモード限定にする。
          if (dark)
            BoxShadow(
              color: base.withValues(alpha: 0.22),
              blurRadius: radius * 0.28,
            ),
          // 接地感を出すドロップシャドウ。
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.16),
            blurRadius: radius * 0.32,
            offset: Offset(0, radius * 0.14),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // カテゴリ色でしっかり塗りつぶす。ダークモードはエナメル風の艶を
            // 出す程度にごく控えめな陰影を、ライトモードは陰影無しの
            // フラットな単色塗りにして「わかりやすさ」を優先する。
            // Positioned.fillが無いとStack内でこのDecoratedBoxが0サイズに
            // 潰れて塗りが消えてしまうので必ず付ける。
            Positioned.fill(
              child: DecoratedBox(
                decoration: dark
                    ? BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.35),
                          radius: 1.0,
                          colors: [
                            Color.lerp(base, Colors.white, 0.10)!,
                            base,
                            Color.lerp(base, Colors.black, 0.18)!,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      )
                    : BoxDecoration(color: base),
              ),
            ),
            // くっきりした輪郭線。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rim.withValues(alpha: 0.95),
                    width: math.max(1.6, radius * 0.045),
                  ),
                ),
              ),
            ),
            Text(
              percentText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
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
