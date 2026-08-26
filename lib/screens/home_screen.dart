import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/recording_limits.dart';
import '../models/journal_entry.dart';
import '../models/summary_level.dart';
import '../services/backend_service.dart';
import '../services/recorder_service.dart';
import '../state/custom_words_store.dart';
import '../state/journal_store.dart';
import '../state/record_trigger_store.dart';
import '../state/settings_store.dart';
import '../widgets/entry_review.dart';
import '../widgets/icon_button_style.dart';
import '../widgets/record_button.dart';
import '../widgets/scrim_text.dart';
import '../widgets/waveform.dart';
import 'custom_dictionary_screen.dart';
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
  Timer? _timer;
  String? _statusMessage;

  String _draftSummary = '';
  DateTime? _draftCreatedAt;
  String? _draftComfortMessage;
  List<DraftItem>? _draftItems;

  RecordTriggerStore? _recordTrigger;
  int _lastHandledRequestId = 0;

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
      _showMessage('マイクの使用が許可されていません');
      return;
    }
    await _recorder.start();
    setState(() {
      _state = RecordButtonState.recording;
      _elapsed = Duration.zero;
      _statusMessage = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _elapsed + const Duration(seconds: 1);
      if (next >= kMaxRecordingDuration) {
        setState(() => _elapsed = kMaxRecordingDuration);
        _stopAndProcess();
        return;
      }
      setState(() => _elapsed = next);
    });
  }

  Future<void> _stopAndProcess() async {
    _timer?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = RecordButtonState.idle);
      _showResultDialog('録音の停止に失敗しました', '$e');
      return;
    }
    setState(() => _state = RecordButtonState.processing);

    if (path == null) {
      setState(() => _state = RecordButtonState.idle);
      _showResultDialog('録音エラー', '録音の保存に失敗しました');
      return;
    }

    if (!mounted) return;

    try {
      final customWords = context.read<CustomWordsStore>().words;
      final summaryLevel = context.read<SettingsStore>().summaryLevel;
      final entry = await _backend.processVoiceMemo(
        File(path),
        customWords: customWords,
        summaryLevel: summaryLevel,
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
      final summaryLevel = context.read<SettingsStore>().summaryLevel;
      final entry = await _backend.processTextMemo(
        text,
        summaryLevel: summaryLevel,
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
      _draftItems = _buildDraftItems(entry);
    });
  }

  void _handleProcessingError(Object e) {
    final message = e is BackendServiceException ? e.message : '$e';
    setState(() {
      _state = RecordButtonState.idle;
      _statusMessage = 'エラー: $message';
    });
    _showResultDialog('処理中にエラーが発生しました', message);
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
    );
    setState(() => _draftItems = null);
    await context.read<JournalStore>().addEntry(entry);
    if (!mounted) return;
    setState(() => _statusMessage = '整理しました：${entry.summary}');
  }

  void _discardDraft() {
    setState(() {
      _draftItems = null;
      _statusMessage = null;
    });
  }

  void _showResultDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
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

  String _statusLabel() {
    switch (_state) {
      case RecordButtonState.idle:
        return 'タップして録音開始';
      case RecordButtonState.recording:
        return '録音中… もう一度タップで停止';
      case RecordButtonState.processing:
        return 'AIが解析中です…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftItems = _draftItems;
    final showComposerFab =
        draftItems == null && _state == RecordButtonState.idle;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_background.png',
              fit: BoxFit.cover,
            ),
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
                                  '${_formatDuration(_elapsed)} / ${_formatDuration(kMaxRecordingDuration)}',
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
                                    _statusLabel(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  if (_state == RecordButtonState.idle) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '1回の録音は最大$kMaxRecordingSeconds秒です',
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
                    bottom: 120,
                    child: FloatingActionButton(
                      heroTag: 'home_text_composer_fab',
                      tooltip: 'テキストで入力',
                      onPressed: _openTextComposer,
                      child: const Icon(Icons.add),
                    ),
                  ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: '設定',
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
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'dictionary', child: Text('カスタム辞書')),
                      PopupMenuItem(
                        value: 'summaryLevel',
                        child: Text('AIの要約度'),
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
            'テキストで入力',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '話せない時はこちらに入力してください。内容は録音と同じようにAIが日記かタスクかを判断します。',
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例: 明日15時に歯医者の予約を入れる',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('AIに解析してもらう'),
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
            'AIの要約度',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '録音・テキストの内容を日記として仕分けるとき、AIがどれくらい短くまとめるかを選べます。タスクの簡潔さには影響しません。',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 20),
          Slider(
            value: index.toDouble(),
            min: 0,
            max: (SummaryLevel.values.length - 1).toDouble(),
            divisions: SummaryLevel.values.length - 1,
            label: level.label,
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
                  l.label,
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
            level.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
