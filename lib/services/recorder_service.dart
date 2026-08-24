import 'dart:io';

import 'package:record/record.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final path =
        '${Directory.systemTemp.path}/voicejournal_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
  }

  Future<String?> stop() => _recorder.stop();

  Future<void> cancel() => _recorder.cancel();

  void dispose() {
    _recorder.dispose();
  }
}
