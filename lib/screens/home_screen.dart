import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/recording_limits.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/review_category.dart';
import '../models/summary_level.dart';
import '../models/usage_status.dart';
import '../services/backend_service.dart';
import '../services/background_recording_service.dart';
import '../services/recorder_service.dart';
import '../services/review_prompt_service.dart';
import '../state/custom_words_store.dart';
import '../state/journal_store.dart';
import '../state/record_trigger_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/entry_review.dart';
import '../widgets/icon_button_style.dart';
import '../widgets/record_button.dart';
import '../widgets/scrim_text.dart';
import '../widgets/waveform.dart';
import 'custom_dictionary_screen.dart';
import 'buy_minutes_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';

const int kRecordPromptQuestionCount = 5;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecorderService _recorder = RecorderService();
  final BackendService _backend = BackendService();
  final ReviewPromptService _reviewPrompt = ReviewPromptService();
  RecordButtonState _state = RecordButtonState.idle;
  bool _isStartingRecording = false;
  Duration _elapsed = Duration.zero;
  Duration _maxDuration = kMaxRecordingDuration;
  Timer? _timer;
  StreamSubscription<RecordingAmplitude>? _amplitudeSub;
  DateTime? _lastSoundAt;
  String? _statusMessage;
  Timer? _processingPhraseTimer;
  int _processingPhraseIndex = 0;
  static const int _processingPhraseCount = 3;

  /// 何を話せばいいか迷わないよう、待機中の波形の上にランダムな問いかけを表示する。
  /// 録音の保存/破棄で待機状態へ戻るたびに次の問いへ差し替える([_rerollPrompt])。
  final Random _promptRandom = Random();
  int _promptIndex = Random().nextInt(kRecordPromptQuestionCount);

  void _rerollPrompt() {
    if (kRecordPromptQuestionCount <= 1) return;
    // 同じ問いが連続で出て「変わっていない」ように見えるのを避けるため、
    // 直前と異なるインデックスが出るまで引き直す。
    int next;
    do {
      next = _promptRandom.nextInt(kRecordPromptQuestionCount);
    } while (next == _promptIndex);
    _promptIndex = next;
  }

  String _promptQuestion(AppLocalizations l10n) => switch (_promptIndex) {
    0 => l10n.recordPromptQuestion1,
    1 => l10n.recordPromptQuestion2,
    2 => l10n.recordPromptQuestion3,
    3 => l10n.recordPromptQuestion4,
    _ => l10n.recordPromptQuestion5,
  };

  String _draftSummary = '';
  DateTime? _draftCreatedAt;
  String? _draftComfortMessage;
  EmotionTag? _draftEmotion;
  List<DraftItem>? _draftItems;
  Set<ReviewCategory> _draftEnabledCategories = {...ReviewCategory.values};

  /// 録音前に「今回話す内容」として絞り込んだカテゴリ。常に全カテゴリ選択済み
  /// の状態から始まり（[_stopAndProcess]/[_submitText]が使い終わった直後に
  /// 全選択へリセットする）、ユーザーが手動で外した場合のみ絞り込まれる。
  /// 空にはできない（最後の1つはタップしても外れない）。
  Set<ReviewCategory> _selectedCategories = {...ReviewCategory.values};

  void _toggleCategory(ReviewCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(category);
        }
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  RecordTriggerStore? _recordTrigger;
  int _lastHandledRequestId = 0;

  late Future<UsageStatus> _usageFuture = _backend.fetchUsageStatus();

  void _refreshUsage() {
    setState(() {
      _usageFuture = _backend.fetchUsageStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trigger = context.read<RecordTriggerStore>();
    if (_recordTrigger != trigger) {
      _recordTrigger?.removeListener(_onRecordTriggered);
      _recordTrigger = trigger;
      _lastHandledRequestId = trigger.requestId;
      trigger.addListener(_onRecordTriggered);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForOrphanedRecording());
  }

  @override
  void dispose() {
    _recordTrigger?.removeListener(_onRecordTriggered);
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _processingPhraseTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  /// 前回、バックグラウンド録音中にAndroidがOSの電池最適化等でプロセスごと
  /// 強制終了した場合、`record`パッケージが逐次書き込んでいた録音ファイルが
  /// 端末に残ったまま気づかれず失われていた。起動のたびに残留ファイルを
  /// 確認し、見つかれば処理するか破棄するかをユーザーに確認する
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  Future<void> _checkForOrphanedRecording() async {
    final orphaned = await RecorderService.findOrphanedRecordings();
    if (orphaned.isEmpty || !mounted) return;

    // 万一2件以上残っていても複雑にしないよう、最新の1件だけ復旧を提案し、
    // それ以外は静かに削除する。
    for (final extra in orphaned.skip(1)) {
      try {
        await File(extra).delete();
      } catch (_) {}
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final shouldRecover = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recoveredRecordingTitle),
        content: Text(l10n.recoveredRecordingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recoveredRecordingProcess),
          ),
        ],
      ),
    );

    final path = orphaned.first;
    if (shouldRecover != true) {
      try {
        await File(path).delete();
      } catch (_) {}
      return;
    }
    await _processRecoveredRecording(path);
  }

  /// [_stopAndProcess]から「録音を止める」部分だけを除いたもの——復旧対象の
  /// ファイルは既に完結しているため、そのままAI仕分けパイプラインへ渡す。
  Future<void> _processRecoveredRecording(String path) async {
    if (!mounted) return;
    final allowedCategories = {...ReviewCategory.values};
    setState(() {
      _state = RecordButtonState.processing;
      _selectedCategories = allowedCategories;
    });
    _startProcessingPhraseCycle();

    try {
      final customWords = context.read<CustomWordsStore>().words;
      final settings = context.read<SettingsStore>();
      final entry = await _backend.processVoiceMemo(
        File(path),
        customWords: customWords,
        summaryLevel: settings.summaryLevel,
        allowedCategories: allowedCategories,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      _applyDraft(entry, allowedCategories);
    } catch (e) {
      if (!mounted) return;
      _handleProcessingError(e);
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  /// 歩きながら・画面を見ずに操作する場面が多いコンセプトのため、目視確認しなくても
  /// 指先の感覚だけで「録音開始/停止/仕分け完了」が分かるようハプティクスを添える。
  void _hapticRecordingStarted() => HapticFeedback.mediumImpact();

  /// 手動タップでの停止はタップ自体が触覚フィードバックを兼ねるので軽く1回、
  /// 無音/最大時間到達による自動停止はユーザーが触れていない状態で起きるため
  /// 気づきやすいよう2回連続で鳴らして区別する。
  Future<void> _hapticRecordingStopped({required bool auto}) async {
    if (auto) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _hapticSortingComplete() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.mediumImpact();
  }

  void _hapticError() => HapticFeedback.heavyImpact();

  /// AI処理中、待機時間のストレスを軽減するため数秒おきに文言を切り替えて
  /// 「今まさに考えている」臨場感を出す。
  void _startProcessingPhraseCycle() {
    _processingPhraseTimer?.cancel();
    setState(() => _processingPhraseIndex = 0);
    _processingPhraseTimer = Timer.periodic(
      const Duration(milliseconds: 1600),
      (_) {
        if (!mounted) return;
        setState(() {
          _processingPhraseIndex =
              (_processingPhraseIndex + 1) % _processingPhraseCount;
        });
      },
    );
  }

  void _stopProcessingPhraseCycle() {
    _processingPhraseTimer?.cancel();
    _processingPhraseTimer = null;
  }

  /// アクションボタン/ロック画面ウィジェットからの起動時、待機中であれば
  /// ユーザー操作なしに録音を自動開始する（既に録音・処理中や下書きレビュー
  /// 表示中なら何もしない）。
  void _onRecordTriggered() {
    final trigger = _recordTrigger;
    if (trigger == null || trigger.requestId == _lastHandledRequestId) return;
    _lastHandledRequestId = trigger.requestId;
    if (_state == RecordButtonState.idle && _draftItems == null) {
      _startRecording();
    }
  }

  Future<void> _onTap() async {
    switch (_state) {
      case RecordButtonState.idle:
        await _startRecording();
      case RecordButtonState.recording:
        await _stopAndProcess();
      case RecordButtonState.processing:
        break;
    }
  }

  Future<void> _startRecording() async {
    // ロック画面ウィジェット等からのディープリンクは、起動時リンクと
    // リンクストリームの両方から同じ録音開始シグナルが飛んでくることがあり、
    // 対策が無いと_startRecording()が同時に2回走って競合する
    // （片方は正常に開始、もう片方はネイティブ側の「録音中」エラーで失敗する）。
    if (_isStartingRecording) return;
    _isStartingRecording = true;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _isStartingRecording = false;
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context)!.micPermissionDenied);
      return;
    }
    try {
      await _recorder.start();
    } catch (e) {
      _isStartingRecording = false;
      // ロック画面ウィジェット等からの起動直後は、画面が実質的に2つ同時に
      // 生きてしまい（原因調査中）、両方が_startRecording()を試みることが
      // ある。片方がネイティブ側の録音を正常に開始できていれば実害は無いので、
      // 「録音中」エラーはこの良性の競合として無視し、既に始まっている
      // 録音にこの画面の状態を追従させる（エラー表示はしない）。
      if (e is PlatformException && e.message == 'alreadyRecording') {
        // 録音自体は既に始まっているので、以下の通常成功時の処理へ続ける。
      } else {
        if (!mounted) return;
        _showResultDialog(
          AppLocalizations.of(context)!.recordingErrorTitle,
          '$e',
        );
        return;
      }
    }
    _isStartingRecording = false;
    if (!mounted) return;
    final isPro = context.read<SubscriptionStore>().isPro;
    setState(() {
      _state = RecordButtonState.recording;
      _elapsed = Duration.zero;
      _maxDuration = maxRecordingDurationFor(isPro);
      _statusMessage = null;
    });
    _hapticRecordingStarted();
    BackgroundRecordingService.updateNotificationText(
      '${_formatDuration(_elapsed)} / ${_formatDuration(_maxDuration)}',
    );
    _lastSoundAt = DateTime.now();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amplitude) {
          if (amplitude.current > kSilenceThresholdDb) {
            _lastSoundAt = DateTime.now();
          }
        });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _elapsed + const Duration(seconds: 1);
      if (next >= _maxDuration) {
        setState(() => _elapsed = _maxDuration);
        _stopAndProcess(auto: true);
        return;
      }
      if (_lastSoundAt != null &&
          DateTime.now().difference(_lastSoundAt!) >=
              kSilenceAutoStopDuration) {
        _stopAndProcess(auto: true);
        return;
      }
      setState(() => _elapsed = next);
      BackgroundRecordingService.updateNotificationText(
        '${_formatDuration(next)} / ${_formatDuration(_maxDuration)}',
      );
    });
  }

  Future<void> _stopAndProcess({bool auto = false}) async {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = RecordButtonState.idle);
      _showResultDialog(
        AppLocalizations.of(context)!.recordingStopFailedTitle,
        '$e',
      );
      return;
    }
    final allowedCategories = _selectedCategories;
    setState(() {
      _state = RecordButtonState.processing;
      _selectedCategories = {...ReviewCategory.values};
    });
    _hapticRecordingStopped(auto: auto);
    _startProcessingPhraseCycle();

    if (path == null) {
      _stopProcessingPhraseCycle();
      if (!mounted) return;
      setState(() => _state = RecordButtonState.idle);
      _showResultDialog(
        AppLocalizations.of(context)!.recordingErrorTitle,
        AppLocalizations.of(context)!.recordingSaveFailed,
      );
      return;
    }

    if (!mounted) return;

    try {
      final customWords = context.read<CustomWordsStore>().words;
      final settings = context.read<SettingsStore>();
      final entry = await _backend.processVoiceMemo(
        File(path),
        customWords: customWords,
        summaryLevel: settings.summaryLevel,
        allowedCategories: allowedCategories,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      _applyDraft(entry, allowedCategories);
    } catch (e) {
      if (!mounted) return;
      _handleProcessingError(e);
    }
  }

  Future<void> _openTextComposer() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _TextComposerSheet(),
    );
    if (text == null || text.trim().isEmpty) return;
    await _submitText(text.trim());
  }

  Future<void> _submitText(String text) async {
    final allowedCategories = _selectedCategories;
    setState(() {
      _state = RecordButtonState.processing;
      _statusMessage = null;
      _selectedCategories = {...ReviewCategory.values};
    });
    _startProcessingPhraseCycle();

    try {
      final settings = context.read<SettingsStore>();
      final locale = Localizations.localeOf(context).languageCode;
      final entry = await _backend.processTextMemo(
        text,
        summaryLevel: settings.summaryLevel,
        allowedCategories: allowedCategories,
        locale: locale,
      );
      if (!mounted) return;
      _applyDraft(entry, allowedCategories);
    } catch (e) {
      if (!mounted) return;
      _handleProcessingError(e);
    }
  }

  void _applyDraft(JournalEntry entry, Set<ReviewCategory> enabledCategories) {
    _stopProcessingPhraseCycle();
    setState(() {
      _state = RecordButtonState.idle;
      _statusMessage = null;
      _draftSummary = entry.summary;
      _draftCreatedAt = entry.createdAt;
      _draftComfortMessage = entry.comfortMessage;
      _draftEmotion = entry.emotion;
      _draftItems = _buildDraftItems(entry);
      _draftEnabledCategories = enabledCategories;
    });
    _hapticSortingComplete();
    _refreshUsage();
  }

  void _handleProcessingError(Object e) {
    _stopProcessingPhraseCycle();
    _hapticError();
    final l10n = AppLocalizations.of(context)!;
    final message = e is BackendServiceException ? e.message : '$e';
    setState(() {
      _state = RecordButtonState.idle;
      _statusMessage = l10n.statusError(message);
      _rerollPrompt();
    });
    final isQuotaExceeded =
        e is BackendServiceException && e.code == 'resource-exhausted';
    final isMonthlyMinutesExceeded =
        e is BackendServiceException && e.isMonthlyMinutesExceeded;
    final isPro = context.read<SubscriptionStore>().isPro;
    _showResultDialog(
      l10n.processingErrorTitle,
      message,
      showUpgrade: isQuotaExceeded && !isPro && !isMonthlyMinutesExceeded,
      showBuyMinutes: isMonthlyMinutesExceeded,
    );
  }

  List<DraftItem> _buildDraftItems(JournalEntry entry) {
    final items = <DraftItem>[];
    for (var i = 0; i < entry.tasks.length; i++) {
      final task = entry.tasks[i];
      items.add(
        DraftItem(
          id: 'task_$i',
          type: DraftItemType.task,
          text: task.title,
          dueHint: task.dueHint,
          dueDate: task.dueDate,
          reminderAt: task.reminderAt,
          reminderEndAt: task.reminderEndAt,
          isAllDay: task.isAllDay,
          notifyAt: task.notifyAt,
        ),
      );
    }
    for (var i = 0; i < entry.notes.length; i++) {
      final note = entry.notes[i];
      items.add(
        DraftItem(
          id: 'note_$i',
          type: DraftItemType.diary,
          text: note.content,
          noteCategory: note.category,
          noteTitle: note.title,
        ),
      );
    }
    return items;
  }

  Future<void> _saveDraft(List<TaskItem> tasks, List<NoteItem> notes) async {
    final entry = JournalEntry(
      createdAt: _draftCreatedAt ?? DateTime.now(),
      summary: _draftSummary,
      tasks: tasks,
      notes: notes,
      comfortMessage: _draftComfortMessage,
      emotion: _draftEmotion,
    );
    setState(() {
      _draftItems = null;
      _rerollPrompt();
    });
    final store = context.read<JournalStore>();
    await store.addEntry(entry);
    if (!mounted) return;
    setState(
      () =>
          _statusMessage = AppLocalizations.of(context)!
              .statusOrganized(entry.summary),
    );
    // 記録の保存に成功し、ユーザーが満足しているはずのこの瞬間だけ、節目の
    // streakに達していればストア評価を依頼する(エラー直後などでは呼ばない)。
    unawaited(_reviewPrompt.maybeRequestForStreak(store.currentStreak));
  }

  void _discardDraft() {
    setState(() {
      _draftItems = null;
      _statusMessage = null;
      _rerollPrompt();
    });
  }

  void _showResultDialog(
    String title,
    String message, {
    bool showUpgrade = false,
    bool showBuyMinutes = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    const radius = 24.0;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Text(message)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (showUpgrade || showBuyMinutes)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (showUpgrade) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              } else if (showBuyMinutes) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BuyMinutesScreen()),
                );
              }
            },
            child: Text(
              showUpgrade
                  ? l10n.planUpgrade
                  : showBuyMinutes
                  ? l10n.buyMinutesCta
                  : 'OK',
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_state) {
      case RecordButtonState.idle:
        return l10n.statusTapToRecord;
      case RecordButtonState.recording:
        return l10n.statusRecording;
      case RecordButtonState.processing:
        // 待機時間のストレスを和らげるため、AIが今どの段階を処理しているか
        // 数秒おきに文言を切り替えて臨場感を出す。
        return [
          l10n.statusProcessing,
          l10n.statusProcessingSorting,
          l10n.statusProcessingFinishing,
        ][_processingPhraseIndex % _processingPhraseCount];
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftItems = _draftItems;
    final showComposerFab =
        draftItems == null && _state == RecordButtonState.idle;
    final l10n = AppLocalizations.of(context)!;
    final isPro = context.watch<SubscriptionStore>().isPro;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: const AppBackgroundImage()),
          SafeArea(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: draftItems != null
                      ? EntryReview(
                          key: const ValueKey('review'),
                          summary: _draftSummary,
                          initialItems: draftItems,
                          enabledCategories: _draftEnabledCategories,
                          onSave: _saveDraft,
                          onDiscard: _discardDraft,
                        )
                      : Center(
                          key: const ValueKey('record'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 何を話せばいいか迷わないよう、待機中だけ波形の上に
                              // ランダムな問いかけを表示する。maintainSizeで
                              // 録音中も高さを確保し、下のボタン/波形の位置が
                              // 録音開始のたびにガタつくのを防ぐ。
                              Visibility(
                                visible: _state == RecordButtonState.idle,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                  ),
                                  child: Text(
                                    _promptQuestion(l10n),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14.5,
                                          height: 1.4,
                                          letterSpacing: 0.15,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Visibility(
                                visible: _state == RecordButtonState.recording,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: ScrimText(
                                  child: Text(
                                    '${_formatDuration(_elapsed)} / ${_formatDuration(_maxDuration)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Waveform(
                                mode: switch (_state) {
                                  RecordButtonState.recording =>
                                    WaveformMode.recording,
                                  RecordButtonState.processing =>
                                    WaveformMode.processing,
                                  RecordButtonState.idle => WaveformMode.idle,
                                },
                              ),
                              const SizedBox(height: 24),
                              Visibility(
                                visible: _state == RecordButtonState.idle,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: _CategoryFilterRow(
                                  selected: _selectedCategories,
                                  onToggle: _toggleCategory,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RecordButton(state: _state, onTap: _onTap),
                              const SizedBox(height: 24),
                              ScrimText(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.15),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          ),
                                      child: Text(
                                        _statusLabel(l10n),
                                        key: ValueKey(
                                          '$_state-${_state == RecordButtonState.processing ? _processingPhraseIndex : 0}',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    if (_state == RecordButtonState.idle) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        isPro
                                            ? l10n.maxRecordingMinutes(
                                                kProMaxRecordingSeconds ~/ 60,
                                              )
                                            : l10n.maxRecordingSeconds(
                                                kMaxRecordingSeconds,
                                              ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<UsageStatus>(
                                        future: _usageFuture,
                                        builder: (context, snapshot) {
                                          final usage = snapshot.data;
                                          if (usage == null) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                            l10n.homeUsageToday(
                                              usage.used,
                                              usage.limit,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                          );
                                        },
                                      ),
                                      FutureBuilder<UsageStatus>(
                                        future: _usageFuture,
                                        builder: (context, snapshot) {
                                          final usage = snapshot.data;
                                          if (usage == null ||
                                              !usage.hasMonthlyBudget) {
                                            return const SizedBox.shrink();
                                          }
                                          final usedMinutes =
                                              (usage.monthlyUsedSeconds ?? 0) ~/
                                              60;
                                          final limitMinutes =
                                              (usage.monthlyLimitSeconds ??
                                                  0) ~/
                                              60;
                                          return Text(
                                            l10n.homeUsageMonth(
                                              usedMinutes,
                                              limitMinutes,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                    if (_statusMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _statusMessage!,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                if (showComposerFab)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: FloatingActionButton(
                      heroTag: 'home_text_composer_fab',
                      tooltip: l10n.textComposeTooltip,
                      onPressed: _openTextComposer,
                      child: const Icon(Icons.add),
                    ),
                  ),
                if (draftItems == null)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _StreakChip(
                        streak: context.watch<JournalStore>().currentStreak,
                      ),
                    ),
                  ),
                if (draftItems == null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 32),
                      tooltip: l10n.settingsTooltip,
                      style: pressableIconButtonStyle(context),
                      onPressed: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, _) =>
                              const SettingsScreen(),
                          transitionsBuilder: (_, animation, _, child) =>
                              SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              ),
                        ),
                      ),
                    ),
                  ),
                if (draftItems == null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      style: pressableIconButtonStyle(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'dictionary') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CustomDictionaryScreen(),
                            ),
                          );
                        } else if (value == 'summaryLevel') {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => const _SummaryLevelSheet(),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'dictionary',
                          height: 56,
                          child: _MenuRow(
                            icon: Icons.edit_outlined,
                            label: l10n.menuCustomDictionary,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'summaryLevel',
                          height: 56,
                          child: _MenuRow(
                            icon: Icons.auto_awesome_outlined,
                            label: l10n.menuSummaryLevel,
                          ),
                        ),
                      ],
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

/// 録音前に「今回話す内容」を絞り込むチップ列。常時表示で、タップで
/// トグル選択（最後の1つは外せない）。ScrimTextと同じ半透明の縁取りで統一する。
class _CategoryFilterRow extends StatelessWidget {
  final Set<ReviewCategory> selected;
  final ValueChanged<ReviewCategory> onToggle;

  const _CategoryFilterRow({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in ReviewCategory.values)
          _CategoryChip(
            label: category.labelFor(l10n),
            icon: category.icon,
            selected: selected.contains(category),
            onTap: () => onToggle(category),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 話せない時用に、録音の代わりにテキストで内容を入力するボトムシート。
/// 入力したテキストは録音と同じAI仕分け（日記かタスクか）にかけられる。
class _TextComposerSheet extends StatefulWidget {
  const _TextComposerSheet();

  @override
  State<_TextComposerSheet> createState() => _TextComposerSheetState();
}

class _TextComposerSheetState extends State<_TextComposerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.textComposerTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.textComposerDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              hintText: l10n.textComposerHint,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(l10n.textComposerSubmit),
            ),
          ),
        ],
      ),
    );
  }
}

/// 録音画面上部中央に出す「🔥 N」の連続記録日数バッジ。streakが0の間は
/// 何も表示しない（記録を始めたばかりのユーザーに「0日」を見せて
/// 気落ちさせないため）。
class _StreakChip extends StatelessWidget {
  final int streak;

  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.streakTooltip(streak),
      child: ScrimText(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// 録音画面右上の「︙」メニュー（カスタム辞書／AIの要約度／日記の文体）の1行分。
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// notes（日記）をAIがどれくらい要約・圧縮するかを3段階のスライダーで選ぶボトムシート。
class _SummaryLevelSheet extends StatelessWidget {
  const _SummaryLevelSheet();

  @override
  Widget build(BuildContext context) {
    final level = context.watch<SettingsStore>().summaryLevel;
    final index = SummaryLevel.values.indexOf(level);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summaryLevelSheetTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.summaryLevelSheetDescription,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 20),
          Slider(
            value: index.toDouble(),
            min: 0,
            max: (SummaryLevel.values.length - 1).toDouble(),
            divisions: SummaryLevel.values.length - 1,
            label: level.labelFor(l10n),
            onChanged: (value) {
              final newLevel = SummaryLevel.values[value.round()];
              context.read<SettingsStore>().setSummaryLevel(newLevel);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in SummaryLevel.values)
                Text(
                  l.labelFor(l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: l == level
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    fontWeight: l == level ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            level.descriptionFor(l10n),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
