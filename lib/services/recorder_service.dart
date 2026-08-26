import 'dart:io';

import 'package:record/record.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// 一定間隔ごとの音量(dBFS)を通知するストリーム。無音検知に使う。
  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _recorder.onAmplitudeChanged(interval);

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
