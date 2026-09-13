import 'package:firebase_core/firebase_core.dart';

/// クラウド同期（テキスト/写真・動画）が失敗した理由の大まかな分類。
/// 従来は成否のboolしか保持しておらず、UIの案内バナーが「一部のデータの
/// 同期に失敗しました」としか言えなかった（原因不明のまま長時間放置される
/// リスク）。FirestoreやStorageの例外コードから、ユーザー自身で対処できる
/// ケース（サインインし直す等）とそうでないケースを大まかに切り分ける。
enum SyncFailureReason {
  network,
  permissionDenied,
  unauthenticated,
  unknown;

  static SyncFailureReason classify(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return SyncFailureReason.permissionDenied;
        case 'unauthenticated':
        case 'user-token-expired':
          return SyncFailureReason.unauthenticated;
        case 'unavailable':
        case 'deadline-exceeded':
        case 'aborted':
        case 'cancelled':
        case 'network-request-failed':
          return SyncFailureReason.network;
      }
    }
    return SyncFailureReason.unknown;
  }
}
