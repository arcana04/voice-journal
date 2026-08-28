import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/weekly_report.dart';
import '../services/backend_service.dart';
import '../services/db_service.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../utils/journal_context_format.dart';
import '../widgets/app_background_image.dart';
import '../widgets/pro_feature_gate.dart';
import '../widgets/weekly_report_content.dart';
import 'weekly_report_history_screen.dart';

class WeeklyReportScreen extends StatefulWidget {
  /// 指定すると、その保存済みレポートをそのまま表示する（AI呼び出し・再集計なし）。
  /// 履歴画面からの遷移で使う。
  final SavedWeeklyReport? savedReport;

  const WeeklyReportScreen({super.key, this.savedReport});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final BackendService _backend = BackendService();
  final ScreenshotController _shareController = ScreenshotController();

  List<JournalEntry> _weekEntries = [];
  Map<EmotionTag, int> _emotionCounts = {};
  List<EmotionTag?> _dailyEmotions = List.filled(7, null);
  int _completedTasks = 0;
  int _diaryCount = 0;
  int _ideaCount = 0;
  int _totalTasks = 0;
  bool _sharing = false;
  late final DateTime _weekStart;
  late final DateTime _weekEnd;
  late final String _weekKey;
  bool get _isHistoryView => widget.savedReport != null;

  Future<WeeklyReportInsights>? _insightsFuture;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedReport;
    if (saved != null) {
      _weekStart = saved.weekStart;
      _weekEnd = saved.weekEnd;
      _weekKey = saved.weekKey;
      _emotionCounts = saved.emotionCounts;
      _dailyEmotions = saved.dailyEmotions;
      _diaryCount = saved.diaryCount;
      _ideaCount = saved.ideaCount;
      _totalTasks = saved.totalTasks;
      _completedTasks = saved.completedTasks;
      _insightsFuture = Future.value(saved.insights);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 月曜始まりの今週（進行中の週）を対象にする。過去に完成した週は履歴として
    // 保存済みのスナップショットのみを見る（ここでの再生成対象にはしない）。
    _weekStart = today.subtract(Duration(days: now.weekday - 1));
    _weekEnd = now;
    _weekKey = _dateKey(_weekStart);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<SubscriptionStore>().isPro) _load();
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    var ideaCount = 0;
    var totalTasks = 0;
    for (final entry in entries) {
      if (entry.emotion != null) {
        emotionCounts[entry.emotion!] = (emotionCounts[entry.emotion!] ?? 0) + 1;
      }
      if (entry.notes.any((n) => n.category == kNoteCategoryFeeling)) {
        diaryCount++;
      }
      if (entry.notes.any((n) => n.category == kNoteCategoryIdea)) {
        ideaCount++;
      }
      totalTasks += entry.tasks.length;
      completedTasks += entry.tasks.where((t) => t.done).length;
    }

    final dailyEmotions = List<EmotionTag?>.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      final dayCounts = <EmotionTag, int>{};
      for (final entry in entries) {
        if (entry.emotion != null && _isSameDate(entry.createdAt, day)) {
          dayCounts[entry.emotion!] = (dayCounts[entry.emotion!] ?? 0) + 1;
        }
      }
      if (dayCounts.isEmpty) return null;
      return dayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    });

    setState(() {
      _weekEntries = entries;
      _emotionCounts = emotionCounts;
      _dailyEmotions = dailyEmotions;
      _completedTasks = completedTasks;
      _diaryCount = diaryCount;
      _ideaCount = ideaCount;
      _totalTasks = totalTasks;
    });

    final locale = Localizations.localeOf(context).languageCode;
    final contextText = formatEntriesAsContext(entries, locale);
    final emotionBreakdown = {
      for (final e in emotionCounts.entries) e.key.id: e.value,
    };
    final future = _backend.generateWeeklyReport(
      context: contextText,
      emotionBreakdown: emotionBreakdown,
      locale: locale,
    );
    setState(() {
      _insightsFuture = future;
    });

    try {
      final insights = await future;
      await DbService.instance.saveWeeklyReport(
        SavedWeeklyReport(
          weekKey: _weekKey,
          weekStart: _weekStart,
          weekEnd: _weekEnd,
          insights: insights,
          emotionCounts: emotionCounts,
          dailyEmotions: dailyEmotions,
          diaryCount: diaryCount,
          ideaCount: ideaCount,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // 生成失敗時は保存しない（_retryで再試行できる）。
    }
  }

  void _retry() {
    setState(() {
      final locale = Localizations.localeOf(context).languageCode;
      final contextText = formatEntriesAsContext(_weekEntries, locale);
      final emotionBreakdown = {
        for (final e in _emotionCounts.entries) e.key.id: e.value,
      };
      _insightsFuture = _backend.generateWeeklyReport(
        context: contextText,
        emotionBreakdown: emotionBreakdown,
        locale: locale,
      );
    });
  }

  Future<void> _shareReport(AppLocalizations l10n) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _shareController.capture(pixelRatio: 3.0);
      if (bytes == null || !mounted) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/weekly_mind_report.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: l10n.weeklyReportShareCaption);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        actions: [
          if (!_isHistoryView)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.weeklyReportHistoryTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyReportHistoryScreen()),
              ),
            ),
          if (_insightsFuture != null)
            FutureBuilder<WeeklyReportInsights>(
              future: _insightsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return IconButton(
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  tooltip: l10n.weeklyReportShareTooltip,
                  onPressed: _sharing ? null : () => _shareReport(l10n),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackgroundImage()),
          SafeArea(
            child: _insightsFuture == null
                ? _AnalyzingView(text: l10n.weeklyReportLoadingInsights)
                : FutureBuilder<WeeklyReportInsights>(
                    future: _insightsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _AnalyzingView(text: l10n.weeklyReportLoadingInsights);
                      }
                      if (snapshot.hasError) {
                        return _ErrorView(
                          title: l10n.weeklyReportErrorTitle,
                          retryLabel: l10n.weeklyReportRetry,
                          onRetry: _retry,
                        );
                      }
                      return RevealIn(
                        child: WeeklyReportContent(
                          insights: snapshot.data!,
                          weekStart: _weekStart,
                          weekEnd: _weekEnd,
                          emotionCounts: _emotionCounts,
                          dailyEmotions: _dailyEmotions,
                          diaryCount: _diaryCount,
                          ideaCount: _ideaCount,
                          totalTasks: _totalTasks,
                          completedTasks: _completedTasks,
                          shareController: _shareController,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// レポートを開いた瞬間の「AIが分析中…」演出。
class _AnalyzingView extends StatefulWidget {
  final String text;

  const _AnalyzingView({required this.text});

  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
