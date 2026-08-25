import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/recording_limits.dart';
import '../models/journal_entry.dart';
import '../services/backend_service.dart';
import '../services/recorder_service.dart';
import '../state/journal_store.dart';
import '../widgets/entry_review.dart';
import '../widgets/record_button.dart';
import '../widgets/waveform.dart';

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

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
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
      final entry = await _backend.processVoiceMemo(File(path));
      if (!mounted) return;
      setState(() {
        _state = RecordButtonState.idle;
        _statusMessage = null;
        _draftSummary = entry.summary;
        _draftCreatedAt = entry.createdAt;
        _draftComfortMessage = entry.comfortMessage;
        _draftItems = _buildDraftItems(entry);
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is BackendServiceException ? e.message : '$e';
      setState(() {
        _state = RecordButtonState.idle;
        _statusMessage = 'エラー: $message';
      });
      _showResultDialog('処理中にエラーが発生しました', message);
    }
  }

  List<DraftItem> _buildDraftItems(JournalEntry entry) {
    final items = <DraftItem>[];
    for (var i = 0; i < entry.tasks.length; i++) {
      final task = entry.tasks[i];
      items.add(DraftItem(
        id: 'task_$i',
        type: DraftItemType.task,
        text: task.title,
        dueHint: task.dueHint,
        dueDate: task.dueDate,
        reminderAt: task.reminderAt,
      ));
    }
    for (var i = 0; i < entry.notes.length; i++) {
      final note = entry.notes[i];
      items.add(DraftItem(
        id: 'note_$i',
        type: DraftItemType.diary,
        text: note.content,
        noteCategory: note.category,
      ));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    return Scaffold(
      appBar: AppBar(title: const Text('VoiceJournal')),
      body: SafeArea(
        child: draftItems != null
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
              Text(
                _state == RecordButtonState.recording
                    ? '${_formatDuration(_elapsed)} / ${_formatDuration(kMaxRecordingDuration)}'
                    : ' ',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Waveform(active: _state == RecordButtonState.recording),
              const SizedBox(height: 48),
              RecordButton(state: _state, onTap: _onTap),
              const SizedBox(height: 32),
              Text(
                _statusLabel(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_state == RecordButtonState.idle) ...[
                const SizedBox(height: 4),
                Text(
                  '1回の録音は最大$kMaxRecordingSeconds秒です',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
