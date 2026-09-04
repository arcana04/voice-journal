import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/weekly_report.dart';
import 'category_donut_chart.dart';
import 'emotion_category_breakdown.dart';
import 'weekly_constellation.dart';
import 'weekly_word_detail_sheet.dart';
import 'weekly_word_scatter.dart';

/// 「仕分け比率」ドーナツチャート用の3カテゴリの色。dataviz skillの検証済み
/// パレット（palette.md）の先頭3スロットをそのまま使用（all-pairsで検証済み）。
class CategoryColors {
  static Color diary(bool dark) => dark ? const Color(0xFF3987E5) : const Color(0xFF2A78D6);
  static Color task(bool dark) => dark ? const Color(0xFFD95926) : const Color(0xFFEB6834);
  static Color idea(bool dark) => dark ? const Color(0xFF199E70) : const Color(0xFF1BAF7A);
}

/// レポート本体。ライブ生成画面・履歴閲覧画面の両方から使う共通の見た目。
/// 共有画像として撮影する[ShareCard]も内包し、画面には見えない位置に配置して
/// キャプチャできるようにしている。
class WeeklyReportContent extends StatefulWidget {
  final WeeklyReportInsights insights;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<MoodMoment> moodMoments;
  final Map<EmotionTag, int> emotionCounts;
  final int diaryCount;
  final int ideaCount;
  final int totalTasks;
  final int completedTasks;
  final ScreenshotController shareController;
  /// 週刊レターが解禁済みか(日曜20:00を過ぎたか、または履歴閲覧)。falseの間は
  /// レター本文の代わりに「もうすぐ届きます」のティザーカードを表示する。
  final bool letterUnlocked;

  const WeeklyReportContent({
    super.key,
    required this.insights,
    required this.weekStart,
    required this.weekEnd,
    required this.moodMoments,
    required this.emotionCounts,
    required this.diaryCount,
    required this.ideaCount,
    required this.totalTasks,
    required this.completedTasks,
    required this.shareController,
    required this.letterUnlocked,
  });

  @override
  State<WeeklyReportContent> createState() => _WeeklyReportContentState();
}

class _WeeklyReportContentState extends State<WeeklyReportContent> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final insights = widget.insights;
    final dateRange =
        '${DateFormat('yyyy.MM.dd').format(widget.weekStart)} – ${DateFormat('MM.dd').format(widget.weekEnd)}';

    final categorySlices = [
      CategorySlice(label: l10n.navDiary, value: widget.diaryCount, color: CategoryColors.diary(dark)),
      CategorySlice(label: l10n.navIdea, value: widget.ideaCount, color: CategoryColors.idea(dark)),
      CategorySlice(label: l10n.navTask, value: widget.totalTasks, color: CategoryColors.task(dark)),
    ];

    // 機能ごとに1画面として横スワイプでめくれるよう、各セクションをページとして並べる。
    final pages = <Widget>[
      _SectionCard(
        icon: Icons.auto_awesome,
        title: l10n.weeklyReportConstellationSectionTitle,
        edgeToEdgeChild: true,
        child: WeeklyConstellation(
          moments: widget.moodMoments,
          weekStart: widget.weekStart,
          locale: locale,
        ),
      ),
      _SectionCard(
        icon: Icons.bubble_chart_outlined,
        title: l10n.weeklyReportKeywordsSectionTitle,
        subtitle: l10n.weeklyReportBrainMapSubtitle,
        child: EmotionCategoryBreakdown(emotionCounts: widget.emotionCounts),
      ),
      _SectionCard(
        icon: Icons.tag,
        title: l10n.weeklyReportWordsSectionTitle,
        child: insights.topKeywords.isEmpty
            ? Text(l10n.weeklyReportWordsEmpty, style: theme.textTheme.bodyMedium)
            : WeeklyWordScatter(
                keywords: insights.topKeywords,
                onTap: (word) => showWeeklyWordDetailSheet(
                  context,
                  keyword: word,
                  weekStart: widget.weekStart,
                  weekEnd: widget.weekEnd,
                ),
              ),
      ),
      _SectionCard(
        icon: Icons.celebration_outlined,
        title: l10n.weeklyReportAchievementSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: widget.completedTasks,
                    label: l10n.weeklyReportTasksCompleted(widget.completedTasks),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    value: widget.diaryCount,
                    label: l10n.weeklyReportDiaryCount(widget.diaryCount),
                    delay: const Duration(milliseconds: 140),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DelayedFadeSlide(
              delay: const Duration(milliseconds: 320),
              child: Text(
                l10n.weeklyReportEncouragement,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      widget.letterUnlocked && insights.weeklyLetter.isNotEmpty
          ? _WeeklyLetterCard(
              title: l10n.weeklyReportLetterSectionTitle,
              letter: insights.weeklyLetter,
            )
          : _WeeklyLetterTeaserCard(title: l10n.weeklyReportLetterSectionTitle),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _MagazineHeader(dateRange: dateRange),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: SingleChildScrollView(child: pages[index]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 画面には表示せず、共有画像キャプチャのためだけにオフキャンバスへ配置。
        Positioned(
          left: -3000,
          top: 0,
          child: Screenshot(
            controller: widget.shareController,
            child: ShareCard(
              dateRange: dateRange,
              insights: insights,
              categorySlices: categorySlices,
              moodMoments: widget.moodMoments,
              weekStart: widget.weekStart,
              locale: locale,
            ),
          ),
        ),
      ],
    );
  }
}

class _MagazineHeader extends StatelessWidget {
  final String dateRange;

  const _MagazineHeader({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY MIND REPORT',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  /// trueの場合、中身(グラフなど)をカード内の左右パディング無しでカードの
  /// 角丸ぎりぎりまで広げる。グラフの表示幅をできるだけ稼ぎたいセクション用。
  final bool edgeToEdgeChild;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.edgeToEdgeChild = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, subtitle != null ? 2 : 0),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(left: 44, right: 16),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            const SizedBox(height: 12),
            edgeToEdgeChild
                ? child
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  ),
          ],
        ),
      ),
    );
  }
}

/// AIが書く「週刊レター」。他のダーク基調のカードとはあえて対比させ、
/// 羊皮紙・手紙らしい見た目（ラベンダー地のグラデーション＋経年による縁の
/// 焼け＋明朝体）にしている。右上に飾りラベル、右下に一輪の枝の挿絵、
/// 末尾に小さなタグラインを添える、実際の便箋のような構成。
class _WeeklyLetterCard extends StatelessWidget {
  final String title;
  final String letter;

  const _WeeklyLetterCard({required this.title, required this.letter});

  static const Color _parchmentLight = Color(0xFFF8F4FB);
  static const Color _parchmentDark = Color(0xFFEAE0F2);
  static const Color _parchmentEdge = Color(0xFFB7A4CE);
  static const Color _ink = Color(0xFF4A4258);
  static const Color _accent = Color(0xFF8B78A8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _parchmentEdge, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.4,
                    colors: [_parchmentLight, _parchmentDark],
                  ),
                ),
              ),
            ),
            // 経年で縁が焼けたような、四隅を暗くするビネット。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    stops: const [0.55, 1.0],
                    colors: [Colors.transparent, _parchmentEdge.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            ),
            // 便箋の隅に添えた、丘と一輪の枝の挿絵。
            Positioned(
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: 160,
                height: 130,
                child: CustomPaint(painter: _LetterDecorationPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history_edu_outlined, size: 20, color: _ink.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.shipporiMincho(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 1.6,
                              color: _ink,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'WEEKLY\nREFLECTION',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: _ink.withValues(alpha: 0.22),
                    thickness: 1,
                    height: 22,
                  ),
                  Text(
                    letter,
                    style: GoogleFonts.shipporiMincho(
                      textStyle: const TextStyle(
                        fontSize: 15,
                        height: 1.9,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(color: _ink.withValues(alpha: 0.16), thickness: 1, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'SMALL STEPS\nBRIGHTER DAYS',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: _accent.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 週刊レターが解禁される(日曜20:00)までの間、同じ便箋の見た目のまま
/// 本文だけを伏せて「特別感」を保つティザーカード。
class _WeeklyLetterTeaserCard extends StatelessWidget {
  final String title;

  const _WeeklyLetterTeaserCard({required this.title});

  static const Color _parchmentLight = _WeeklyLetterCard._parchmentLight;
  static const Color _parchmentDark = _WeeklyLetterCard._parchmentDark;
  static const Color _parchmentEdge = _WeeklyLetterCard._parchmentEdge;
  static const Color _ink = _WeeklyLetterCard._ink;
  static const Color _accent = _WeeklyLetterCard._accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _parchmentEdge, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.4,
                    colors: [_parchmentLight, _parchmentDark],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    stops: const [0.55, 1.0],
                    colors: [Colors.transparent, _parchmentEdge.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: 160,
                height: 130,
                child: CustomPaint(painter: _LetterDecorationPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history_edu_outlined, size: 20, color: _ink.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.shipporiMincho(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 1.6,
                              color: _ink,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'WEEKLY\nREFLECTION',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: _ink.withValues(alpha: 0.22),
                    thickness: 1,
                    height: 22,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_clock_outlined, size: 30, color: _accent.withValues(alpha: 0.7)),
                        const SizedBox(height: 14),
                        Text(
                          l10n.weeklyReportLetterLocked,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.shipporiMincho(
                            textStyle: TextStyle(
                              fontSize: 14,
                              height: 1.8,
                              color: _ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Divider(color: _ink.withValues(alpha: 0.16), thickness: 1, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'SMALL STEPS\nBRIGHTER DAYS',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: _accent.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 週刊レターの便箋の隅に添える、柔らかい丘のシルエットと一輪の枝の挿絵。
class _LetterDecorationPainter extends CustomPainter {
  static const Color _stem = Color(0xFF8B78A8);
  static const Color _petal = Color(0xFFA78BC9);
  static const Color _petalCenter = Color(0xFFD9C7EC);
  static const Color _hill = Color(0xFFB7A4CE);

  void _drawLeaf(Canvas canvas, Offset base, double angle, double length) {
    final tip = base + Offset(math.cos(angle), math.sin(angle)) * length;
    final control = Offset((base.dx + tip.dx) / 2 + 7, (base.dy + tip.dy) / 2);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = _stem.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.15, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height * 0.86)
      ..lineTo(size.width * 0.8, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.76)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = _hill.withValues(alpha: 0.20));

    final stemStart = Offset(size.width * 0.86, size.height);
    final stemEnd = Offset(size.width * 0.60, size.height * 0.22);
    final stemPath = Path()
      ..moveTo(stemStart.dx, stemStart.dy)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.5, stemEnd.dx, stemEnd.dy);
    canvas.drawPath(
      stemPath,
      Paint()
        ..color = _stem.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    _drawLeaf(canvas, Offset(size.width * 0.78, size.height * 0.56), math.pi * 0.85, 20);
    _drawLeaf(canvas, Offset(size.width * 0.70, size.height * 0.38), math.pi * 1.1, 16);

    for (var i = 0; i < 5; i++) {
      final a = (i / 5) * math.pi * 2;
      final petalCenter = stemEnd + Offset(math.cos(a), math.sin(a)) * 5.5;
      canvas.drawCircle(petalCenter, 4.0, Paint()..color = _petal.withValues(alpha: 0.55));
    }
    canvas.drawCircle(stemEnd, 3.0, Paint()..color = _petalCenter.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _LetterDecorationPainter oldDelegate) => false;
}

/// 達成数の統計タイル。登場時にフェード+下からのスライドと同時に、
/// 数字が0から実際の値までカウントアップする。
class _StatTile extends StatefulWidget {
  final int value;
  final String label;
  final Duration delay;

  const _StatTile({
    required this.value,
    required this.label,
    this.delay = Duration.zero,
  });

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _started ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final count = (widget.value * t).round();
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 一定の遅延の後にフェード+下からのスライドで登場するだけの汎用ラッパー。
class _DelayedFadeSlide extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const _DelayedFadeSlide({required this.delay, required this.child});

  @override
  State<_DelayedFadeSlide> createState() => _DelayedFadeSlideState();
}

class _DelayedFadeSlideState extends State<_DelayedFadeSlide> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _started ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// データ到着時の「立ち上がる」リビール演出。フェード＋下からのスライド。
class RevealIn extends StatefulWidget {
  final Widget child;

  const RevealIn({super.key, required this.child});

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// SNS共有用に撮影する縦長サマリーカード（画面には表示しない）。
class ShareCard extends StatelessWidget {
  final String dateRange;
  final WeeklyReportInsights insights;
  final List<CategorySlice> categorySlices;
  final List<MoodMoment> moodMoments;
  final DateTime weekStart;
  final String locale;

  const ShareCard({
    super.key,
    required this.dateRange,
    required this.insights,
    required this.categorySlices,
    required this.moodMoments,
    required this.weekStart,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WEEKLY MIND REPORT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              dateRange,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (insights.moodHeadline.isNotEmpty)
              Text(
                insights.moodHeadline,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            const SizedBox(height: 20),
            WeeklyConstellation(moments: moodMoments, weekStart: weekStart, locale: locale),
            const SizedBox(height: 20),
            CategoryDonutChart(slices: categorySlices),
            if (insights.highlightQuote.quote.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '“${insights.highlightQuote.quote}”',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Voice Brain',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
