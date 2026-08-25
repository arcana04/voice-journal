import 'package:flutter/foundation.dart';

/// アクションボタン・ロック画面ウィジェットなど、アプリ外から「録音を今すぐ開始」
/// と指示されたことを、画面ツリーの各所（RootScreen・HomeScreen）に伝える橋渡し役。
class RecordTriggerStore extends ChangeNotifier {
  int requestId = 0;

  void requestRecordNow() {
    requestId++;
    notifyListeners();
  }
}
