import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Siri/ショートカットからアプリを開かずに録音できるようにするための
/// ペアリングを一度だけ行う。仕組みはApple Watch単体録音
/// （lib/services/watch_pairing_service.dart）と同じ mintWatchPairingToken を
/// 使い回し、結果をMethodChannel経由でiOSネイティブ側のKeychainに保存する
/// （ios/Runner/SiriRecording/参照）。Android側はまだ対応していない。
class SiriRecordingSetupService {
  static const _channel = MethodChannel('voicejournal/siri_recording');
  static const _hasPairedPref = 'siri_recording_paired';

  final AuthService _auth = AuthService();

  /// サインイン済みならバックグラウンドで一度だけペアリングする。
  /// 失敗してもアプリの起動は妨げない（Siri機能が使えないだけ）。
  Future<void> ensurePairedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasPairedPref) ?? false) return;

    try {
      await _auth.ensureSignedIn();

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('mintWatchPairingToken');
      final result = await callable.call<Map<String, dynamic>>({'locale': 'ja'});
      final data = result.data;

      await _channel.invokeMethod<bool>('completePairing', {
        'customToken': data['customToken'] as String,
        'deviceId': data['deviceId'] as String,
        'deviceSecret': data['deviceSecret'] as String,
      });

      await prefs.setBool(_hasPairedPref, true);
    } catch (_) {
      // Siriバックグラウンド録音は付加機能のため、失敗しても通常のアプリ利用は継続する。
    }
  }
}
