import 'package:flutter/foundation.dart';

/// アイデア画面の「AIで深掘り」ボタンから、相談タブへ「このアイデアを
/// 3つの切り口で深掘りして」という依頼を橋渡しするストア。RootScreenは
/// これを見て相談タブへ切り替え、KnowledgeBaseScreenはこれを見て自動的に
/// ブレインストームを開始しチャットへ結果を積む。IndexedStackで両方の
/// 画面が常にマウントされたままなので、[RecordTriggerStore]と同じ
/// 「共有ストア経由での画面間トリガー」パターンを踏襲している。
class IdeaBrainstormRequest {
  final String title;
  final String content;

  const IdeaBrainstormRequest({required this.title, required this.content});
}

class IdeaBrainstormRequestStore extends ChangeNotifier {
  IdeaBrainstormRequest? pending;

  void request({required String title, required String content}) {
    pending = IdeaBrainstormRequest(title: title, content: content);
    notifyListeners();
  }

  void consume() {
    pending = null;
  }
}
