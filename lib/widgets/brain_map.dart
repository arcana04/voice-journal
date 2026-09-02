import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_localizations.dart';
import '../models/weekly_report.dart';

/// 週刊脳内レポートの「脳内マップ」。キーワードごとに大きさ(重要度)・色
/// (紐づく感情のブレンド)が異なる、発光する円形タグを重ならないように
/// 浮かせて配置するワードクラウド。タップすると、そのキーワードが出てきた
/// 記録一覧をボトムシートで表示する。
class BrainMap extends StatelessWidget {
  final List<BrainMapBubble> bubbles;
  final String locale;

  const BrainMap({super.key, required this.bubbles, required this.locale});

  static const double _minRadius = 30;
  static const double _maxRadius = 58;
  static const double _height = 220;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (bubbles.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(l10n.weeklyReportNoKeywords, style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _layoutBubbles(bubbles, constraints.maxWidth, _height);
          return Stack(
            children: [
              for (final placed in layout)
                Positioned(
                  left: placed.center.dx - placed.radius,
                  top: placed.center.dy - placed.radius,
                  width: placed.radius * 2,
                  height: placed.radius * 2,
                  child: _BubbleView(
                    bubble: placed.bubble,
                    radius: placed.radius,
                    onTap: () => _showBubbleSheet(context, placed.bubble),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showBubbleSheet(BuildContext context, BrainMapBubble bubble) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(bubble.colorValue);

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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bubble.keyword,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bubble.matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.weeklyReportBrainMapSheetEmpty,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: bubble.matches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = bubble.matches[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${DateFormat('M/d', locale).format(m.time)}(${DateFormat.E(locale).format(m.time)})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (m.emotion != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: m.emotion!.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.emotion!.labelFor(l10n),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.snippet,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
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
        );
      },
    );
  }
}

class _PlacedBubble {
  final BrainMapBubble bubble;
  final Offset center;
  final double radius;

  const _PlacedBubble({required this.bubble, required this.center, required this.radius});
}

/// 大きいバブルから順に、中心から渦巻き状に外側へ探索しながら、既に置いた
/// バブルと重ならない最初の位置に配置する(ワードクラウドでよく使われる
/// アルキメデス螺旋探索の簡易版)。
List<_PlacedBubble> _layoutBubbles(List<BrainMapBubble> bubbles, double width, double height) {
  if (bubbles.isEmpty || width <= 0) return [];

  final maxWeight = bubbles.map((b) => b.weight).reduce(math.max);
  final sorted = [...bubbles]..sort((a, b) => b.weight.compareTo(a.weight));

  final placed = <_PlacedBubble>[];
  final centerX = width / 2;
  final centerY = height / 2;

  for (final bubble in sorted) {
    final normalized = maxWeight <= 1 ? 1.0 : math.sqrt(bubble.weight / maxWeight);
    final radius =
        BrainMap._minRadius + (BrainMap._maxRadius - BrainMap._minRadius) * normalized.clamp(0.0, 1.0);

    Offset? spot;
    const angleStep = 0.5;
    const radiusStep = 4.0;
    final maxRadiusSearch = math.sqrt(width * width + height * height);
    var angle = 0.0;
    var spiralRadius = 0.0;
    while (spiralRadius <= maxRadiusSearch) {
      final candidate = Offset(
        centerX + spiralRadius * math.cos(angle),
        centerY + spiralRadius * math.sin(angle) * 0.65,
      );
      final clamped = Offset(
        candidate.dx.clamp(radius, width - radius),
        candidate.dy.clamp(radius, height - radius),
      );
      final overlaps = placed.any((p) {
        final minDist = p.radius + radius + 4;
        return (p.center - clamped).distanceSquared < minDist * minDist;
      });
      if (!overlaps) {
        spot = clamped;
        break;
      }
      angle += angleStep;
      spiralRadius += radiusStep * (angleStep / (2 * math.pi));
    }
    spot ??= Offset(centerX, centerY);
    placed.add(_PlacedBubble(bubble: bubble, center: spot, radius: radius));
  }

  return placed;
}

class _BubbleView extends StatelessWidget {
  final BrainMapBubble bubble;
  final double radius;
  final VoidCallback onTap;

  const _BubbleView({required this.bubble, required this.radius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(bubble.colorValue);
    final fontSize = (radius * 0.34).clamp(10.0, 16.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: radius * 0.7, spreadRadius: 1),
          ],
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: [
              Color.lerp(color, Colors.white, 0.35)!,
              color,
              Color.lerp(color, Colors.black, 0.25)!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 感情の色が透けて見える程度に抑えた、ガラス玉風のツヤ・虹色の縁取り。
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/brain_map/bubble_overlay.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                bubble.keyword,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
