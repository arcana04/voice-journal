import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/backend_service.dart';
import '../services/recorder_service.dart';
import '../state/journal_store.dart';
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
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndProcess() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _state = RecordButtonState.processing);

    if (path == null) {
      setState(() => _state = RecordButtonState.idle);
      _showMessage('録音の保存に失敗しました');
      return;
    }

    if (!mounted) return;

    try {
      final entry = await _backend.processVoiceMemo(File(path));
      if (!mounted) return;
      await context.read<JournalStore>().addEntry(entry);
      if (!mounted) return;
      setState(() {
        _state = RecordButtonState.idle;
        _statusMessage = '整理しました：${entry.summary}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = RecordButtonState.idle;
        _statusMessage = null;
      });
      _showMessage(e is BackendServiceException ? e.message : '処理中にエラーが発生しました');
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('VoiceJournal')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _state == RecordButtonState.recording
                    ? _formatDuration(_elapsed)
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
