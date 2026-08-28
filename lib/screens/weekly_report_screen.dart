import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/weekly_report.dart';
import '../services/backend_service.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../utils/journal_context_format.dart';
import '../widgets/app_background_image.dart';
import '../widgets/pro_feature_gate.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final BackendService _backend = BackendService();

  List<JournalEntry> _weekEntries = [];
  Map<EmotionTag, int> _emotionCounts = {};
  int _completedTasks = 0;
  int _diaryCount = 0;
  late final DateTime _weekStart;
  late final DateTime _weekEnd;

  Future<WeeklyReportInsights>? _insightsFuture;

  @override
  void initState() {
    super.initState();
    _weekEnd = DateTime.now();
    _weekStart = _weekEnd.subtract(const Duration(days: 7));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<SubscriptionStore>().isPro) _load();
    });
  }

  Future<void> _load() async {
    await context.read<JournalStore>().load();
    if (!mounted) return;

    final entries = context
        .read<JournalStore>()
        .entries
        .where((e) => e.createdAt.isAfter(_weekStart))
        .toList();

    final emotionCounts = <EmotionTag, int>{};
    var completedTasks = 0;
    var diaryCount = 0;
    for (final entry in entries) {
      if (entry.emotion != null) {
        emotionCounts[entry.emotion!] = (emotionCounts[entry.emotion!] ?? 0) + 1;
      }
      if (entry.notes.any((n) => n.category == kNoteCategoryFeeling)) {
        diaryCount++;
      }
      completedTasks += entry.tasks.where((t) => t.done).length;
    }

    setState(() {
      _weekEntries = entries;
      _emotionCounts = emotionCounts;
      _completedTasks = completedTasks;
      _diaryCount = diaryCount;
    });

    final locale = Localizations.localeOf(context).languageCode;
    final contextText = formatEntriesAsContext(entries, locale);
    setState(() {
      _insightsFuture = _backend.generateWeeklyReport(
        context: contextText,
        locale: locale,
      );
    });
  }

  void _retry() {
    setState(() {
      final locale = Localizations.localeOf(context).languageCode;
      final contextText = formatEntriesAsContext(_weekEntries, locale);
      _insightsFuture = _backend.generateWeeklyReport(
        context: contextText,
        locale: locale,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateRange =
        '${DateFormat.MMMd(locale).format(_weekStart)} – ${DateFormat.MMMd(locale).format(_weekEnd)}';
    final isPro = context.watch<SubscriptionStore>().isPro;

    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyReportTitle)),
        body: ProFeatureGate(
          title: l10n.weeklyReportTitle,
          description: l10n.weeklyReportProLockedDescription,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyReportTitle),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackgroundImage()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                  dateRange,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  icon: Icons.emoji_emotions_outlined,
                  title: l10n.weeklyReportEmotionSectionTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _emotionCounts.isEmpty
                          ? Text(
                              l10n.weeklyReportNoEmotionData,
                              style: theme.textTheme.bodyMedium,
                            )
                          : _EmotionBreakdown(counts: _emotionCounts),
                      const SizedBox(height: 12),
                      _InsightsSection(
                        future: _insightsFuture,
                        onRetry: _retry,
                        builder: (insights) => Text(
                          insights.emotionNarrative,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.tag,
                  title: l10n.weeklyReportKeywordsSectionTitle,
                  child: _InsightsSection(
                    future: _insightsFuture,
                    onRetry: _retry,
                    builder: (insights) => insights.topKeywords.isEmpty
                        ? Text(
                            l10n.weeklyReportNoKeywords,
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < insights.topKeywords.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Text(
                                    '${i + 1}. #${insights.topKeywords[i].keyword}'
                                    '（${insights.topKeywords[i].count}）',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.auto_awesome,
                  title: l10n.weeklyReportIdeasSectionTitle,
                  child: _InsightsSection(
                    future: _insightsFuture,
                    onRetry: _retry,
                    builder: (insights) => insights.shiningIdeas.isEmpty
                        ? Text(
                            l10n.weeklyReportNoIdeas,
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final idea in insights.shiningIdeas)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        idea.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        idea.reason,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
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
                              value: '$_completedTasks',
                              label: l10n.weeklyReportTasksCompleted(_completedTasks),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              value: '$_diaryCount',
                              label: l10n.weeklyReportDiaryCount(_diaryCount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.weeklyReportEncouragement,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: l10n.weeklyReportAdviceSectionTitle,
                  child: _InsightsSection(
                    future: _insightsFuture,
                    onRetry: _retry,
                    builder: (insights) => Text(
                      insights.advice,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({required this.icon, required this.title, required this.child});

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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmotionBreakdown extends StatelessWidget {
  final Map<EmotionTag, int> counts;

  const _EmotionBreakdown({required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(entry.key.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.labelFor(l10n), style: theme.textTheme.bodySmall),
                          Text('${entry.value}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : entry.value / total,
                          minHeight: 7,
                          backgroundColor:
                              theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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

/// [future]の状態（読み込み中・エラー・完了）に応じて[builder]の結果を表示する。
class _InsightsSection extends StatelessWidget {
  final Future<WeeklyReportInsights>? future;
  final VoidCallback onRetry;
  final Widget Function(WeeklyReportInsights insights) builder;

  const _InsightsSection({
    required this.future,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<WeeklyReportInsights>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.weeklyReportLoadingInsights,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weeklyReportErrorTitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
              TextButton(onPressed: onRetry, child: Text(l10n.weeklyReportRetry)),
            ],
          );
        }
        return builder(snapshot.data!);
      },
    );
  }
}
