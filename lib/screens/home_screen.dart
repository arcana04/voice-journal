import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart' show Amplitude;

import '../config/recording_limits.dart';
import '../l10n/app_localizations.dart';
import '../models/diary_style.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/summary_level.dart';
import '../models/usage_status.dart';
import '../services/backend_service.dart';
import '../services/background_recording_service.dart';
import '../services/recorder_service.dart';
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
import 'paywall_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecorderService _recorder = RecorderService();
  final BackendService _backend = BackendService();
  RecordButtonState _state = RecordButtonState.idle;
  Duration _elapsed = Duration.zero;
  Duration _maxDuration = kMaxRecordingDuration;
  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  DateTime? _lastSoundAt;
  String? _statusMessage;

  String _draftSummary = '';
  DateTime? _draftCreatedAt;
  String? _draftComfortMessage;
  EmotionTag? _draftEmotion;
  List<DraftItem>? _draftItems;

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
  void dispose() {
    _recordTrigger?.removeListener(_onRecordTriggered);
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    super.dispose();
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
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context)!.micPermissionDenied);
      return;
    }
    await _recorder.start();
    if (!mounted) return;
    final isPro = context.read<SubscriptionStore>().isPro;
    setState(() {
      _state = RecordButtonState.recording;
      _elapsed = Duration.zero;
      _maxDuration = maxRecordingDurationFor(isPro);
      _statusMessage = null;
    });
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
        _stopAndProcess();
        return;
      }
      if (_lastSoundAt != null &&
          DateTime.now().difference(_lastSoundAt!) >=
              kSilenceAutoStopDuration) {
        _stopAndProcess();
        return;
      }
      setState(() => _elapsed = next);
      BackgroundRecordingService.updateNotificationText(
        '${_formatDuration(next)} / ${_formatDuration(_maxDuration)}',
      );
    });
  }

  Future<void> _stopAndProcess() async {
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
    setState(() => _state = RecordButtonState.processing);

    if (path == null) {
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
        diaryStyle: settings.diaryStyle,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      _applyDraft(entry);
    } catch (e) {
      if (!mounted) return;
      _handleProcessingError(e);
    }
  }

  Future<void> _openTextComposer() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _TextComposerSheet(),
    );
    if (text == null || text.trim().isEmpty) return;
    await _submitText(text.trim());
  }

  Future<void> _submitText(String text) async {
    setState(() {
      _state = RecordButtonState.processing;
      _statusMessage = null;
    });

    try {
      final settings = context.read<SettingsStore>();
      final locale = Localizations.localeOf(context).languageCode;
      final entry = await _backend.processTextMemo(
        text,
        summaryLevel: settings.summaryLevel,
        diaryStyle: settings.diaryStyle,
        locale: locale,
      );
      if (!mounted) return;
      _applyDraft(entry);
    } catch (e) {
      if (!mounted) return;
      _handleProcessingError(e);
    }
  }

  void _applyDraft(JournalEntry entry) {
    setState(() {
      _state = RecordButtonState.idle;
      _statusMessage = null;
      _draftSummary = entry.summary;
      _draftCreatedAt = entry.createdAt;
      _draftComfortMessage = entry.comfortMessage;
      _draftEmotion = entry.emotion;
      _draftItems = _buildDraftItems(entry);
    });
    _refreshUsage();
  }

  void _handleProcessingError(Object e) {
    final l10n = AppLocalizations.of(context)!;
    final message = e is BackendServiceException ? e.message : '$e';
    setState(() {
      _state = RecordButtonState.idle;
      _statusMessage = l10n.statusError(message);
    });
    final isQuotaExceeded =
        e is BackendServiceException && e.code == 'resource-exhausted';
    final isPro = context.read<SubscriptionStore>().isPro;
    _showResultDialog(
      l10n.processingErrorTitle,
      message,
      showUpgrade: isQuotaExceeded && !isPro,
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
    setState(() => _draftItems = null);
    await context.read<JournalStore>().addEntry(entry);
    if (!mounted) return;
    setState(
      () => _statusMessage = AppLocalizations.of(
        context,
      )!.statusOrganized(entry.summary),
    );
  }

  void _discardDraft() {
    setState(() {
      _draftItems = null;
      _statusMessage = null;
    });
  }

  void _showResultDialog(
    String title,
    String message, {
    bool showUpgrade = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          if (showUpgrade)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: Text(l10n.planUpgrade),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
        return l10n.statusProcessing;
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
          Positioned.fill(
            child: const AppBackgroundImage(),
          ),
          SafeArea(
            child: Stack(
              children: [
                draftItems != null
                    ? EntryReview(
                        summary: _draftSummary,
                        initialItems: draftItems,
                        onSave: _saveDraft,
                        onDiscard: _discardDraft,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              active: _state == RecordButtonState.recording,
                            ),
                            const SizedBox(height: 48),
                            RecordButton(state: _state, onTap: _onTap),
                            const SizedBox(height: 32),
                            ScrimText(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _statusLabel(l10n),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
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
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l10n.settingsTooltip,
                    style: pressableIconButtonStyle(context),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    style: pressableIconButtonStyle(context),
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
                          builder: (_) => const _SummaryLevelSheet(),
                        );
                      } else if (value == 'diaryStyle') {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const _DiaryStyleSheet(),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'dictionary',
                        child: Text(l10n.menuCustomDictionary),
                      ),
                      PopupMenuItem(
                        value: 'summaryLevel',
                        child: Text(l10n.menuSummaryLevel),
                      ),
                      PopupMenuItem(
                        value: 'diaryStyle',
                        child: Text(l10n.menuDiaryStyle),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.textComposerTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.textComposerDescription,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.textComposerHint,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(l10n.textComposerSubmit),
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

/// notes（日記）の文体を選ぶボトムシート。Pro限定のスタイルは未加入だとロック表示にし、
/// タップするとペイウォールへ誘導する。
class _DiaryStyleSheet extends StatelessWidget {
  const _DiaryStyleSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = context.watch<SettingsStore>().diaryStyle;
    final isPro = context.watch<SubscriptionStore>().isPro;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diaryStyleSheetTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.diaryStyleSheetDescription,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final style in DiaryStyle.values)
                      _DiaryStyleOption(
                        style: style,
                        selected: style == selected,
                        locked: style.requiresPro && !isPro,
                        onTap: () {
                          if (style.requiresPro && !isPro) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PaywallScreen(),
                              ),
                            );
                            return;
                          }
                          context.read<SettingsStore>().setDiaryStyle(style);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryStyleOption extends StatelessWidget {
  final DiaryStyle style;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _DiaryStyleOption({
    required this.style,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Text(style.labelFor(l10n), style: theme.textTheme.titleSmall),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ],
        ),
        subtitle: Text(style.descriptionFor(l10n)),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : (locked ? Text(l10n.planUpgrade) : null),
      ),
    );
  }
}
