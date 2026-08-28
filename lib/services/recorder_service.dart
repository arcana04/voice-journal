import 'dart:io';

import 'package:record/record.dart';

import 'background_recording_service.dart';

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
    // バックグラウンド/画面オフでも録音を継続できるよう、Androidではここで
    // フォアグラウンドサービスを開始する（iOSはInfo.plistの設定のみで対応）。
    await BackgroundRecordingService.start();
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    await BackgroundRecordingService.stop();
    return path;
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    await BackgroundRecordingService.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
