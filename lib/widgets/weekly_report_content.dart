import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import '../l10n/app_localizations.dart';
import '../models/weekly_report.dart';
import 'brain_map.dart';
import 'category_donut_chart.dart';
import 'mental_wave_chart.dart';
import 'weekly_constellation.dart';

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
class WeeklyReportContent extends StatelessWidget {
  final WeeklyReportInsights insights;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<MoodMoment> moodMoments;
  final List<BrainMapBubble> brainMapBubbles;
  final int diaryCount;
  final int ideaCount;
  final int totalTasks;
  final int completedTasks;
  final ScreenshotController shareController;

  const WeeklyReportContent({
    super.key,
    required this.insights,
    required this.weekStart,
    required this.weekEnd,
    required this.moodMoments,
    required this.brainMapBubbles,
    required this.diaryCount,
    required this.ideaCount,
    required this.totalTasks,
    required this.completedTasks,
    required this.shareController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final dateRange =
        '${DateFormat('yyyy.MM.dd').format(weekStart)} – ${DateFormat('MM.dd').format(weekEnd)}';

    final categorySlices = [
      CategorySlice(label: l10n.navDiary, value: diaryCount, color: CategoryColors.diary(dark)),
      CategorySlice(label: l10n.navIdea, value: ideaCount, color: CategoryColors.idea(dark)),
      CategorySlice(label: l10n.navTask, value: totalTasks, color: CategoryColors.task(dark)),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _MagazineHeader(dateRange: dateRange),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.auto_awesome,
              title: l10n.weeklyReportConstellationSectionTitle,
              child: WeeklyConstellation(
                moments: moodMoments,
                weekStart: weekStart,
                locale: locale,
              ),
            ),
            if (insights.weeklyLetter.isNotEmpty) ...[
              const SizedBox(height: 16),
              _WeeklyLetterCard(
                title: l10n.weeklyReportLetterSectionTitle,
                letter: insights.weeklyLetter,
              ),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.show_chart,
              title: l10n.weeklyReportMentalWaveSectionTitle,
              child: MentalWaveChart(
                moments: moodMoments,
                weekStart: weekStart,
                locale: locale,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.bubble_chart_outlined,
              title: l10n.weeklyReportKeywordsSectionTitle,
              subtitle: l10n.weeklyReportBrainMapSubtitle,
              child: BrainMap(bubbles: brainMapBubbles, locale: locale),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.format_quote,
              title: l10n.weeklyReportHighlightSectionTitle,
              child: insights.highlightQuote.quote.isEmpty
                  ? Text(l10n.weeklyReportNoHighlight, style: theme.textTheme.bodyMedium)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“${insights.highlightQuote.quote}”',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          insights.highlightQuote.reason,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
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
                          value: '$completedTasks',
                          label: l10n.weeklyReportTasksCompleted(completedTasks),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: '$diaryCount',
                          label: l10n.weeklyReportDiaryCount(diaryCount),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.weeklyReportEncouragement,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.tips_and_updates_outlined,
              title: l10n.weeklyReportAdviceSectionTitle,
              child: Text(insights.advice, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
        // 画面には表示せず、共有画像キャプチャのためだけにオフキャンバスへ配置。
        Positioned(
          left: -3000,
          top: 0,
          child: Screenshot(
            controller: shareController,
            child: ShareCard(
              dateRange: dateRange,
              insights: insights,
              categorySlices: categorySlices,
              moodMoments: moodMoments,
              weekStart: weekStart,
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

  const _SectionCard({required this.icon, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// AIが書く「週刊レター」。他のダーク基調のカードとはあえて対比させ、
/// 羊皮紙・手紙らしい見た目（クリーム地のグラデーション＋経年による縁の
/// 焼け＋明朝体）にしている。
class _WeeklyLetterCard extends StatelessWidget {
  final String title;
  final String letter;

  const _WeeklyLetterCard({required this.title, required this.letter});

  static const Color _parchmentLight = Color(0xFFF4E8C8);
  static const Color _parchmentDark = Color(0xFFDFC38C);
  static const Color _parchmentEdge = Color(0xFFB08D4F);
  static const Color _ink = Color(0xFF4A3524);

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
                    colors: [Colors.transparent, _parchmentEdge.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu_outlined, size: 20, color: _ink.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
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
                    ],
                  ),
                  Divider(
                    color: _ink.withValues(alpha: 0.25),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
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
                'VoiceJournal',
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
