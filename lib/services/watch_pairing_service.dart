import 'dart:async';

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

/// [WatchPairingService.pairWatch]がWatch側からの完了確認を受け取れなかった
/// 場合の結果。ペアリング情報自体は送信できているため「失敗」ではないが、
/// Watch側で実際にトークン交換が終わったかは確認できていない、という
/// あいまいな状態をUI側に伝えるための専用の戻り値。
enum WatchPairingOutcome { confirmed, pending }

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

  /// Watchへペアリング情報を送るだけでなく、Watch側（[PairingReceiver.swift]）
  /// が実際にトークン交換まで完了したという返信を一定時間待ち受ける。以前は
  /// [_watch.updateApplicationContext]が例外を投げずに戻った時点で無条件に
  /// 成功扱いにしていたが、これは「iPhoneからWatchへの中継を試みた」ことしか
  /// 保証せず、Watchアプリが即座にフォアグラウンドでない・Bluetoothが不安定・
  /// customTokenのTTL切れ等でWatch側の交換が失敗しても、ユーザーには「成功」
  /// としか見えなかった。
  Future<WatchPairingOutcome> pairWatch({required String locale}) async {
    await _auth.ensureSignedIn();

    if (!await isWatchAvailable) {
      throw WatchPairingException(currentLocalizations().watchNotPairedMessage);
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('mintWatchPairingToken');
      final result = await callable.call<Map<String, dynamic>>({'locale': locale});
      final data = result.data;
      final deviceId = data['deviceId'] as String;

      final ackCompleter = Completer<bool>();
      late final StreamSubscription messageSub;
      late final StreamSubscription contextSub;
      void onAck(Map<String, dynamic> payload) {
        if (payload['pairingAckDeviceId'] != deviceId) return;
        if (!ackCompleter.isCompleted) {
          ackCompleter.complete(payload['pairingSucceeded'] == true);
        }
      }

      messageSub = _watch.messageStream.listen(onAck);
      contextSub = _watch.contextStream.listen(onAck);

      await _watch.updateApplicationContext({
        'customToken': data['customToken'] as String,
        'deviceId': deviceId,
        'deviceSecret': data['deviceSecret'] as String,
      });

      // Watch側が既に古いapplicationContextとしてACKを受信済み・かつ再送しない
      // ケースにも備え、現在のreceivedApplicationContextsも即座に確認する。
      for (final ctx in await _watch.receivedApplicationContexts) {
        onAck(ctx);
      }

      bool acked;
      try {
        acked = await ackCompleter.future.timeout(const Duration(seconds: 15));
      } on TimeoutException {
        return WatchPairingOutcome.pending;
      } finally {
        await messageSub.cancel();
        await contextSub.cancel();
      }

      if (!acked) {
        throw WatchPairingException(currentLocalizations().genericProcessingError);
      }
      return WatchPairingOutcome.confirmed;
    } on FirebaseFunctionsException catch (e) {
      throw WatchPairingException(e.message ?? currentLocalizations().genericProcessingError);
    }
  }
}
