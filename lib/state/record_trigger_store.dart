import 'package:flutter/foundation.dart';

/// アクションボタン・ロック画面ウィジェットなど、アプリ外から「録音を今すぐ開始」
/// と指示されたことを、画面ツリーの各所（RootScreen・HomeScreen）に伝える橋渡し役。
///
/// 起動直後は`app_links`の起動時リンク取得とリンクストリームの両方から同じ
/// URLが届く上、（原因未特定だが）起動直後にRootScreen/HomeScreenが複数
/// 同時に生きてしまうことがあり、対策が無いと同じ「録音を開始して」の指示で
/// 複数回_startRecording()が呼ばれてネイティブ側の「録音中」エラーになる。
/// 個々の画面側ではなく、全画面が共有するこのStoreの入り口で短時間の
/// 重複要求をまとめて無視することで、呼び出し元の数に関わらず確実に防ぐ。
class RecordTriggerStore extends ChangeNotifier {
  static const _debounce = Duration(seconds: 2);

  int requestId = 0;
  DateTime? _lastRequestAt;

  void requestRecordNow() {
    final now = DateTime.now();
    if (_lastRequestAt != null && now.difference(_lastRequestAt!) < _debounce) {
      return;
    }
    _lastRequestAt = now;
    requestId++;
    notifyListeners();
  }
}
