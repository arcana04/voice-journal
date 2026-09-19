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
  List<MoodMoment> _moodMoments = [];
  int _completedTasks = 0;
  int _diaryCount = 0;
  int _ideaCount = 0;
  int _totalTasks = 0;
  bool _sharing = false;
  late final DateTime _weekStart;
  late final DateTime _weekEnd;
  late final DateTime _letterCutoff;
  late final bool _letterUnlocked;
  late final String _weekKey;
  bool get _isHistoryView => widget.savedReport != null;

  /// 「先週比」比較用の、前週の保存済みスナップショット。無ければ比較UIは
  /// 表示しない([WeeklyReportDelta.hasPrevious]がfalseになる)。
  SavedWeeklyReport? _previousReport;

  Future<WeeklyReportInsights>? _insightsFuture;
  /// [_load]を呼んだかどうか。初回はisProがまだfalseで[build]がペイウォールを
  /// 表示するだけの画面と、その場で購入してPro化した後の再ビルドを区別する
  /// ため——両方とも同じ画面インスタンスのままなので、[_insightsFuture]が
  /// nullでisProがtrueになった時点で一度だけ[_load]を呼ぶ。
  bool _proLoadTriggered = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedReport;
    if (saved != null) {
      _weekStart = saved.weekStart;
      _weekEnd = saved.weekEnd;
      _letterCutoff = saved.weekEnd;
      // 履歴は既に完了した週のスナップショットなので、レターは常に解禁済み扱い。
      _letterUnlocked = true;
      _weekKey = saved.weekKey;
      _emotionCounts = saved.emotionCounts;
      _moodMoments = saved.moodMoments;
      _diaryCount = saved.diaryCount;
      _ideaCount = saved.ideaCount;
      _totalTasks = saved.totalTasks;
      _completedTasks = saved.completedTasks;
      _insightsFuture = Future.value(saved.insights);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreviousReport());
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 月曜始まりの今週（進行中の週）を対象にする。過去に完成した週は履歴として
    // 保存済みのスナップショットのみを見る（ここでの再生成対象にはしない）。
    _weekStart = today.subtract(Duration(days: now.weekday - 1));
    // 週刊レターは日曜20:00に「解禁」される特別な演出——だが、これは表示上の
    // タイミングの話であって、「どの記録をこの週の集計に含めるか」とは
    // 別物として扱う。以前は解禁後、_weekEndを日曜20:00に固定していたため、
    // 日曜20:00〜月曜0:00の間に作られた記録が、今週（_weekEndより後という
    // 理由で除外）にも来週（次週の_weekStartは月曜0:00で、それより前という
    // 理由で除外）にも属せず、毎週必ず取りこぼされていた
    // （[[project_voicejournal_knowledge_base_chat]]参照）。
    // 集計対象の期間は常に「月曜0:00〜翌月曜0:00」のフルの週とし、まだ週の
    // 途中なら「今」で打ち切るだけにする。表示上の解禁タイミング判定
    // （_letterUnlocked）はこれまでどおり日曜20:00の_letterCutoffで行う。
    _letterCutoff = _weekStart.add(const Duration(days: 6, hours: 20));
    _letterUnlocked = !now.isBefore(_letterCutoff);
    final weekTrueEnd = _weekStart.add(const Duration(days: 7));
    // ちょうど週が終わり切った瞬間ちょうど(翌月曜0:00)を含めてしまうと、
    // 日付だけの表示（MM.dd）が翌週の日付にずれて見えるため、表示上は
    // 週の最後の瞬間(日曜23:59:59.999)に丸めておく。実質的な集計結果には
    // 影響しない（その1ミリ秒の間に記録が作られることは実運用上ない）。
    _weekEnd = now.isBefore(weekTrueEnd)
        ? now
        : weekTrueEnd.subtract(const Duration(milliseconds: 1));
    _weekKey = _dateKey(_weekStart);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPreviousReport();
      if (context.read<SubscriptionStore>().isPro) {
        _proLoadTriggered = true;
        _load();
      }
    });
  }

  /// 「先週比」比較用に、前週(週の開始日を7日遡った週)の保存済み
  /// スナップショットを読み込む。無ければ[_previousReport]はnullのまま
  /// (=比較UI非表示)。
  ///
  /// 前週のスナップショットが、日曜20:00（レター解禁＝週の確定）より前に
  /// 開かれて保存された途中経過である場合は、比較対象として使わない
  /// ——中途半端な週と比較すると誤解を招く前週比になってしまうため
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  /// 以前はweekEndが「日曜20:00固定」だったことを利用してこれを逆算して
  /// いたが、weekEndの意味を「週の実際の終端（月曜0:00〜翌月曜0:00の
  /// フルの週、記録を取りこぼさないための対応）」に変更したため、weekEndから
  /// はもう判定できない。保存時点の解禁状態をそのまま[SavedWeeklyReport.
  /// letterUnlocked]に保持し、それを直接見る。
  Future<void> _loadPreviousReport() async {
    final previousWeekStart = _weekStart.subtract(const Duration(days: 7));
    final previousWeekKey = _dateKey(previousWeekStart);
    final previous = await DbService.instance.getWeeklyReportByWeekKey(previousWeekKey);
    if (!mounted) return;
    final isComplete = previous != null && previous.letterUnlocked;
    setState(() => _previousReport = isComplete ? previous : null);
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
        .where((e) =>
            !e.createdAt.isBefore(_weekStart) && e.createdAt.isBefore(_weekEnd))
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

    final dailyEmotionCounts = List<Map<EmotionTag, int>>.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      final dayCounts = <EmotionTag, int>{};
      for (final entry in entries) {
        if (entry.emotion != null && _isSameDate(entry.createdAt, day)) {
          dayCounts[entry.emotion!] = (dayCounts[entry.emotion!] ?? 0) + 1;
        }
      }
      return dayCounts;
    });

    final moodMoments = [
      for (final entry in entries)
        if (entry.emotion != null)
          MoodMoment(
            time: entry.createdAt,
            tag: entry.emotion!,
            textLength: entry.notes
                .where((n) => n.category == kNoteCategoryFeeling)
                .fold(0, (sum, n) => sum + n.content.length),
          ),
    ];

    // 記録の増減だけでなく「削除して同数だけ作り直した」ケースも見分ける
    // ための署名。件数が一致していても、実体が別の記録に入れ替わっていれば
    // 不一致になりキャッシュを再利用しない（脳内マップ等が実際の記録内容と
    // 食い違って表示される事故を防ぐ）。
    final entryIdsSignature = (entries.map((e) => e.id).toList()..sort()).join(',');

    setState(() {
      _weekEntries = entries;
      _emotionCounts = emotionCounts;
      _moodMoments = moodMoments;
      _completedTasks = completedTasks;
      _diaryCount = diaryCount;
      _ideaCount = ideaCount;
      _totalTasks = totalTasks;
    });

    // 前回この(week_key, locale)で保存したスナップショットと日記・アイデア・
    // タスクの件数(かつ記録idの集合)が一致するなら、その間に記録が変わって
    // いないとみなしてAI呼び出しを省略する。LLMの出力は毎回同じにはならない
    // ため、何も変わっていないのに開くたびにキーワード（脳内マップ）やレター
    // の中身がブレてしまうのを防ぐ。localeも一致条件に含める（かつキーも
    // week_key+localeにする）ことで、表示言語を切り替えた際に別言語の
    // キャッシュを誤って使ったり、上書きで破壊したりしないようにする
    // （[[project_voicejournal_knowledge_base_chat]]参照）。
    final currentLocale = Localizations.localeOf(context).languageCode;
    final cached = await DbService.instance
        .getWeeklyReportByWeekKeyAndLocale(_weekKey, currentLocale);
    if (!mounted) return;
    if (cached != null &&
        cached.entryIdsSignature == entryIdsSignature &&
        cached.diaryCount == diaryCount &&
        cached.ideaCount == ideaCount &&
        cached.totalTasks == totalTasks &&
        cached.completedTasks == completedTasks) {
      setState(() {
        _insightsFuture = Future.value(cached.insights);
      });
      // 保存時点ではまだレター解禁前（週の途中）だったが、その後日曜20:00を
      // 過ぎて解禁済みになったケース。記録の中身が変わらない限りここで
      // キャッシュがそのまま再利用されsaveWeeklyReportが呼ばれないため、
      // 何もしないとDB上のletterUnlockedがfalseのまま固定されてしまう。
      // 次週にこの週を「先週」として比較する際、_loadPreviousReportが
      // letterUnlocked==falseを「未確定の途中経過」と誤判定し、本来出る
      // べき先週比バッジが永久に出なくなる（[[project_voicejournal_weekly_report]]
      // 参照）。解禁状態が変わった分だけ更新して保存し直す。
      if (_letterUnlocked && !cached.letterUnlocked) {
        await DbService.instance.saveWeeklyReport(
          SavedWeeklyReport(
            id: cached.id,
            weekKey: cached.weekKey,
            weekStart: cached.weekStart,
            weekEnd: _weekEnd,
            insights: cached.insights,
            emotionCounts: cached.emotionCounts,
            dailyEmotionCounts: cached.dailyEmotionCounts,
            moodMoments: cached.moodMoments,
            brainMapBubbles: cached.brainMapBubbles,
            diaryCount: cached.diaryCount,
            ideaCount: cached.ideaCount,
            totalTasks: cached.totalTasks,
            completedTasks: cached.completedTasks,
            entryIdsSignature: cached.entryIdsSignature,
            createdAt: cached.createdAt,
            locale: cached.locale,
            letterUnlocked: true,
          ),
        );
      }
      return;
    }

    final contextText = formatEntriesAsContext(entries, currentLocale);
    final emotionBreakdown = {
      for (final e in emotionCounts.entries) e.key.id: e.value,
    };
    final future = _backend.generateWeeklyReport(
      context: contextText,
      emotionBreakdown: emotionBreakdown,
      locale: currentLocale,
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
          dailyEmotionCounts: dailyEmotionCounts,
          moodMoments: moodMoments,
          brainMapBubbles: const [],
          diaryCount: diaryCount,
          ideaCount: ideaCount,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          entryIdsSignature: entryIdsSignature,
          createdAt: DateTime.now(),
          locale: currentLocale,
          letterUnlocked: _letterUnlocked,
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

    if (!_isHistoryView && !_proLoadTriggered && _insightsFuture == null) {
      // 画面を開いた時点ではPro未契約でペイウォールが表示されていたが、
      // その場で購入して戻ってきたケース（画面インスタンスはそのまま）。
      // initStateの一度きりのチェックでは拾えないので、ここでisProが
      // trueになった最初のビルドで一度だけ読み込みを始める。
      _proLoadTriggered = true;
      _load();
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
                      final emotionCounts = _isHistoryView
                          ? widget.savedReport!.emotionCounts
                          : _emotionCounts;
                      final comparison = WeeklyReportDelta.compare(
                        currentEmotionCounts: emotionCounts,
                        currentCompletedTasks: _completedTasks,
                        currentDiaryCount: _diaryCount,
                        previous: _previousReport,
                      );
                      return RevealIn(
                        child: WeeklyReportContent(
                          insights: snapshot.data!,
                          weekStart: _weekStart,
                          weekEnd: _weekEnd,
                          moodMoments: _moodMoments,
                          emotionCounts: emotionCounts,
                          diaryCount: _diaryCount,
                          ideaCount: _ideaCount,
                          totalTasks: _totalTasks,
                          completedTasks: _completedTasks,
                          shareController: _shareController,
                          letterUnlocked: _letterUnlocked,
                          comparison: comparison,
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
