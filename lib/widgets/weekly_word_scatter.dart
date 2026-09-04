import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/weekly_report.dart';

/// 「今週のよく話した言葉」。AIが抽出したキーワード([WeeklyReportKeyword])を、
/// 話題に上った頻度(count)に応じた大きさのガラス風ピルにしてWrapで流し込む。
/// カード1枚ごとにわずかな回転・上下ズレ・添え物の小さな粒を付けて不規則な
/// 散らばりに見せる(乱数はキーワード文字列自体から決定的に導くので、再描画
/// のたびに位置が動いたりはしない)。タップするとその単語を含む記録を
/// [onTap]経由で呼び出し元に伝える。
class WeeklyWordScatter extends StatefulWidget {
  final List<WeeklyReportKeyword> keywords;
  final ValueChanged<String> onTap;

  const WeeklyWordScatter({super.key, required this.keywords, required this.onTap});

  @override
  State<WeeklyWordScatter> createState() => _WeeklyWordScatterState();
}

class _WeeklyWordScatterState extends State<WeeklyWordScatter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500 + widget.keywords.length * 70),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final keywords = widget.keywords;
    final maxCount = keywords.map((k) => k.count).fold(1, (a, b) => math.max(a, b));
    final count = keywords.length;

    return Wrap(
      spacing: 14,
      runSpacing: 18,
      children: [
        for (var i = 0; i < count; i++)
          _EntranceCard(
            controller: _controller,
            index: i,
            count: count,
            child: _WordCard(
              keyword: keywords[i],
              color: color,
              weight: keywords[i].count.clamp(1, maxCount) / maxCount,
              seed: i,
              onTap: () => widget.onTap(keywords[i].keyword),
            ),
          ),
      ],
    );
  }
}

/// [child]を下から飛び出してくるように登場させる。カードの並び順に
/// わずかずつ開始をずらし(スタッガー)、easeOutBackでちょっとした
/// バウンド感を出す。
class _EntranceCard extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final int count;
  final Widget child;

  const _EntranceCard({
    required this.controller,
    required this.index,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / count) * 0.5;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        final opacity = v.clamp(0.0, 1.0);
        final dy = (1 - v) * 46;
        final scale = (0.82 + 0.18 * v).clamp(0.0, 1.08);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _WordCard extends StatelessWidget {
  final WeeklyReportKeyword keyword;
  final Color color;
  /// そのキーワードの話題頻度を0..1で表した比重(最頻出=1.0)。カードの
  /// 大きさに反映する。
  final double weight;
  final int seed;
  final VoidCallback onTap;

  const _WordCard({
    required this.keyword,
    required this.color,
    required this.weight,
    required this.seed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // キーワード文字列由来の決定的な乱数。同じ結果を毎回再現する。
    final rng = math.Random(keyword.keyword.hashCode ^ (seed * 0x9E3779B1));
    final angle = (rng.nextDouble() - 0.5) * 0.22; // 約±6.3度
    final dy = (rng.nextDouble() - 0.5) * 14;
    final dotCorner = rng.nextInt(4);
    final dotSize = 5.0 + rng.nextDouble() * 5.0;

    final fontSize = 15.0 + weight * 8.0;
    final vPad = 10.0 + weight * 4.0;
    final hPad = 18.0 + weight * 8.0;

    final pill = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: _pillDecoration(dark),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _glassHighlight(dark),
              Text(
                keyword.keyword,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dark
                      ? Color.lerp(color, Colors.white, 0.35)
                      : Color.lerp(color, Colors.black, 0.15),
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dot = IgnorePointer(
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: dark ? 0.35 : 0.28),
        ),
      ),
    );

    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: angle,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            pill,
            Positioned(
              top: dotCorner < 2 ? -dotSize * 0.5 : null,
              bottom: dotCorner >= 2 ? -dotSize * 0.5 : null,
              left: dotCorner.isEven ? -dotSize * 0.5 : null,
              right: dotCorner.isOdd ? -dotSize * 0.5 : null,
              child: dot,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _pillDecoration(bool dark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: dark ? 0.30 : 0.20),
          color.withValues(alpha: dark ? 0.14 : 0.08),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: dark ? 0.16 : 0.65),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: dark ? 0.22 : 0.12),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _glassHighlight(bool dark) {
    return Positioned(
      left: 4,
      right: 4,
      top: 2,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
