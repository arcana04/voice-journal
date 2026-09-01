import 'package:cloud_functions/cloud_functions.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../l10n/l10n_utils.dart';
import 'auth_service.dart';

class WatchPairingException implements Exception {
  final String message;
  WatchPairingException(this.message);

  @override
  String toString() => message;
}

/// Apple Watchのスタンドアロン録音アプリをペアリングする。
///
/// iPhone側でmintWatchPairingToken（functions/src/index.ts）を呼んで
/// customToken・deviceId・deviceSecretを発行し、WatchConnectivityの
/// updateApplicationContextでWatchへ中継する。Watch側はこれをFirebase Auth
/// のREST APIと交換してWatch専用のrefreshTokenを得て、以降iPhoneの状態に
/// 依存せず動作する（ios/VoiceJournalWatch/PairingReceiver.swift参照）。
/// iPhoneとWatchが同時にBluetooth到達圏内にある必要がある、一度きりの操作。
class WatchPairingService {
  final AuthService _auth = AuthService();
  final WatchConnectivity _watch = WatchConnectivity();

  Future<bool> get isWatchAvailable async {
    if (!await _watch.isSupported) return false;
    return _watch.isPaired;
  }

  Future<void> pairWatch({required String locale}) async {
    await _auth.ensureSignedIn();

    if (!await isWatchAvailable) {
      throw WatchPairingException(currentLocalizations().watchNotPairedMessage);
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('mintWatchPairingToken');
      final result = await callable.call<Map<String, dynamic>>({'locale': locale});
      final data = result.data;

      await _watch.updateApplicationContext({
        'customToken': data['customToken'] as String,
        'deviceId': data['deviceId'] as String,
        'deviceSecret': data['deviceSecret'] as String,
      });
    } on FirebaseFunctionsException catch (e) {
      throw WatchPairingException(e.message ?? currentLocalizations().genericProcessingError);
    }
  }
}
