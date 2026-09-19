import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Android側で今まさに書き込み中の録音ファイルのパス（無ければnull）。
  /// オーファン録音スキャン([findOrphanedRecordings])が、開始直後でまだ
  /// [isRecording]がtrueを返す前のこのファイルを誤って削除しないよう、
  /// 除外パスとして使う。
  String? _androidCurrentPath;

  /// 録音ファイルの保存先ディレクトリ。iOSの`NSTemporaryDirectory`
  /// （[Directory.systemTemp]相当）は「アプリ未起動中にOSがいつでも中身を
  /// 消してよい」領域と定義されており、強制終了からのリカバリ（次回起動まで
  /// ファイルが残っている前提）と矛盾する。ネイティブ側
  /// （ios/Runner/SiriRecording/BackgroundAudioRecorder.swift）と同じ
  /// `Application Support/recordings`ディレクトリを使うことで、Android/iOS
  /// 双方とも永続領域に保存されるようにする。
  static Future<Directory> _recordingsDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/recordings');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

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

  /// 前回アプリが録音の途中で強制終了された場合に残る、未処理のまま端末に
  /// 残っている録音ファイル一覧を返す（新しい順）。Android版は電池最適化が
  /// 厳しい端末でバックグラウンド録音中にOSがプロセスごと強制終了することが
  /// あり、`record`パッケージは音声を逐次ディスクへ書き込むため、その場合
  /// ファイル自体は生き残るが今まで検知・復旧する手段が無く、ユーザーが
  /// 気づかないまま録音が失われていた（[[project_voicejournal_knowledge_base_chat]]
  /// 参照）。呼び出し側は現在進行中の録音がある場合、そのパスを[excludePath]
  /// で除外すること。
  static Future<List<String>> findOrphanedRecordings({String? excludePath}) async {
    try {
      final dir = await _recordingsDir();
      if (!await dir.exists()) return const [];
      final entries = await dir
          .list()
          .where(
            (e) =>
                e is File &&
                e.path != excludePath &&
                e.path.split(Platform.pathSeparator).last.startsWith('voicejournal_') &&
                e.path.endsWith('.m4a'),
          )
          .cast<File>()
          .toList();
      entries.sort((a, b) => b.path.compareTo(a.path));
      return entries.map((f) => f.path).toList();
    } catch (_) {
      return const [];
    }
  }

  /// バックグラウンド復帰時、UI側の状態（[RecordButtonState]等）が実際の
  /// 録音状態と食い違っていないかを確認するために使う。OSがメモリ不足で
  /// Flutter側のウィジェット状態だけを作り直した場合でも、ネイティブの
  /// 録音エンジン自体は生きていることがあるため、UIを復元する判断材料になる。
  Future<bool> isRecording() {
    if (Platform.isIOS) {
      return _channel
          .invokeMethod<bool>('isRecording')
          .then((recording) => recording ?? false);
    }
    // `_androidRecorder`(package:record)はFlutterエンジン単位で発行される
    // recorderIdでネイティブ側の録音セッションと紐付いているため、OSが
    // メモリ整理でActivity/エンジンごと作り直すと、この[RecorderService]も
    // 新しい`AudioRecorder()`インスタンス（＝別recorderId）になり、実際は
    // 録音が続いているのに`isRecording()`がfalseを返してしまう。フォア
    // グラウンドサービスの起動状態は`start()`/`stop()`/`cancel()`と厳密に
    // 対で管理されるOSレベルの状態でエンジンの生き死にに影響されないため、
    // こちらを正とする。
    return FlutterForegroundTask.isRunningService;
  }

  /// 今まさに書き込み中の録音ファイルのパス（無ければnull）。
  /// オーファン録音スキャンの除外パスとして呼び出し側（home_screen.dart）が使う。
  Future<String?> currentRecordingPath() {
    if (Platform.isIOS) {
      return _channel.invokeMethod<String>('currentPath');
    }
    return Future.value(_androidCurrentPath);
  }

  Future<void> start() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('start');
    } else {
      final dir = await _recordingsDir();
      final path =
          '${dir.path}/voicejournal_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _androidCurrentPath = path;
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
    _androidCurrentPath = null;
    await BackgroundRecordingService.stop();
    return path;
  }

  Future<void> cancel() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('cancel');
    } else {
      await _androidRecorder!.cancel();
    }
    _androidCurrentPath = null;
    await BackgroundRecordingService.stop();
  }

  void dispose() {
    _androidRecorder?.dispose();
  }
}
