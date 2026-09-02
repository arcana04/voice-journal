import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:record/record.dart' as record_pkg;

import 'background_recording_service.dart';

/// 録音中の音量（dBFS）。`package:record`の`Amplitude`と同じスケール
/// （無音に近いほど-160に近づく）で統一している。
class RecordingAmplitude {
  const RecordingAmplitude(this.current);

  final double current;
}

/// iOSはネイティブ録音エンジン（ios/Runner/SiriRecording/BackgroundAudioRecorder.swift）
/// をMethodChannel経由で使う。UIBackgroundModes=audio対応のため、録音中に画面を
/// ロックしても継続できる。AndroidはOS標準のバックグラウンド制約が異なるため、
/// 従来どおり`record`パッケージを直接使う。
class RecorderService {
  static const _channel = MethodChannel('voicejournal/recording');

  final record_pkg.AudioRecorder? _androidRecorder =
      Platform.isIOS ? null : record_pkg.AudioRecorder();

  Future<bool> hasPermission() {
    if (Platform.isIOS) {
      return _channel
          .invokeMethod<bool>('hasPermission')
          .then((granted) => granted ?? false);
    }
    return _androidRecorder!.hasPermission();
  }

  /// 一定間隔ごとの音量(dBFS)を通知するストリーム。無音検知に使う。
  Stream<RecordingAmplitude> onAmplitudeChanged(Duration interval) {
    if (Platform.isIOS) {
      late final StreamController<RecordingAmplitude> controller;
      Timer? timer;
      controller = StreamController<RecordingAmplitude>(
        onListen: () {
          timer = Timer.periodic(interval, (_) async {
            final value = await _channel.invokeMethod<double>('getAmplitude');
            if (!controller.isClosed) {
              controller.add(RecordingAmplitude(value ?? -160.0));
            }
          });
        },
        onCancel: () => timer?.cancel(),
      );
      return controller.stream;
    }
    return _androidRecorder!
        .onAmplitudeChanged(interval)
        .map((amplitude) => RecordingAmplitude(amplitude.current));
  }

  Future<void> start() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('start');
    } else {
      final path =
          '${Directory.systemTemp.path}/voicejournal_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _androidRecorder!.start(
        const record_pkg.RecordConfig(encoder: record_pkg.AudioEncoder.aacLc),
        path: path,
      );
    }
    // バックグラウンド/画面オフでも録音を継続できるよう、Androidではここで
    // フォアグラウンドサービスを開始する（iOSはInfo.plistの設定のみで対応）。
    await BackgroundRecordingService.start();
  }

  Future<String?> stop() async {
    final path = Platform.isIOS
        ? await _channel.invokeMethod<String>('stop')
        : await _androidRecorder!.stop();
    await BackgroundRecordingService.stop();
    return path;
  }

  Future<void> cancel() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('cancel');
    } else {
      await _androidRecorder!.cancel();
    }
    await BackgroundRecordingService.stop();
  }

  void dispose() {
    _androidRecorder?.dispose();
  }
}
